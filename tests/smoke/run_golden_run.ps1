# Golden run per docs/plans/initial-plan.md
param(
    [string]$BuildDir = "build",
    [string]$Config = "Release"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$Exe = Join-Path $RepoRoot "$BuildDir/bin/$Config/austrian_abm.exe"

if (-not (Test-Path $Exe)) {
    Write-Error "Executable not found: $Exe. Build first."
}

$ReportDir = Join-Path $RepoRoot "reports-golden"
if (Test-Path $ReportDir) { Remove-Item -Recurse -Force $ReportDir }

$env:AUSTRIAN_ABM_GOOD_STAGES = "2"
$env:AUSTRIAN_ABM_REPORT_DIR = $ReportDir
$env:AUSTRIAN_ABM_GRID_WIDTH = "224"
$env:AUSTRIAN_ABM_GRID_HEIGHT = "224"
$env:AUSTRIAN_ABM_OCCUPANCY = "0.1"
$env:AUSTRIAN_ABM_NATURAL_RATE = "0.08"
$env:AUSTRIAN_ABM_POLICY_RATE = "0.02"
$env:AUSTRIAN_ABM_RATE_SHOCK_STEP = "6"
$env:AUSTRIAN_ABM_CATALOG_PATH = (Join-Path $RepoRoot "data/vic3_catalog.json")

Push-Location $RepoRoot
try {
    & $Exe --steps 12 --seed 42
    if ($LASTEXITCODE -ne 0) {
        throw "Simulation exited with code $LASTEXITCODE"
    }

    $Jsonl = Join-Path $ReportDir "market_history.jsonl"
    if (-not (Test-Path $Jsonl)) { throw "Missing market_history.jsonl" }

    $lines = Get-Content $Jsonl
    if ($lines.Count -lt 12) { throw "Expected 12 log lines, got $($lines.Count)" }

    $hasTrade = $false
    foreach ($line in $lines) {
        if ($line -match '"trades_count":([1-9][0-9]*)') { $hasTrade = $true }
    }
    if (-not $hasTrade) { throw "Golden run produced no trades (TRADES_COUNT always 0)" }

    $hasProduction = $false
    foreach ($line in $lines) {
        if ($line -match '"production_count":([1-9][0-9]*)') { $hasProduction = $true }
    }
    if (-not $hasProduction) { throw "Golden run produced no food production" }

    $hasInvestment = $false
    foreach ($line in $lines) {
        if ($line -match '"investment_count":([1-9][0-9]*)') { $hasInvestment = $true }
    }
    if (-not $hasInvestment) { throw "Golden run produced no capital investment" }

    $hasServices = $false
    $hasStapleVariety = $false
    foreach ($line in $lines) {
        if ($line -match '"total_svc":([1-9][0-9]*)') { $hasServices = $true }
        if ($line -match '"total_food":([1-9][0-9]*)') { $hasStapleVariety = $true }
    }
    if (-not $hasServices -and -not $hasStapleVariety) {
        throw "Golden run produced no services or staple goods"
    }

    $hasIndustrialGoods = $false
    foreach ($line in $lines) {
        if ($line -match '"total_ind":([1-9][0-9]*)') { $hasIndustrialGoods = $true }
    }
    if (-not $hasIndustrialGoods) { throw "Golden run produced no industrial (IND) goods" }

    $hasCredit = $false
    foreach ($line in $lines) {
        if ($line -match '"credit_created":([1-9][0-9]*)') { $hasCredit = $true }
    }
    if (-not $hasCredit) { throw "Golden run produced no bank credit" }

    $preShockRoundabout = 0
    $postShockRoundabout = 0
    $preShockRate = 0.0
    $postShockRate = 0.0
    foreach ($line in $lines) {
        if ($line -match '"step":(\d+)') {
            $step = [int]$Matches[1]
            $roundabout = 0
            $rate = 0.0
            if ($line -match '"roundabout_count":(\d+)') { $roundabout = [int]$Matches[1] }
            if ($line -match '"effective_rate":([0-9.]+)') { $rate = [double]$Matches[1] }
            if ($step -lt 6) {
                if ($roundabout -gt $preShockRoundabout) { $preShockRoundabout = $roundabout }
                $preShockRate = $rate
            } elseif ($step -ge 6) {
                if ($roundabout -gt $postShockRoundabout) { $postShockRoundabout = $roundabout }
                $postShockRate = $rate
            }
        }
    }
    if ($postShockRate -le $preShockRate) {
        throw "Rate shock did not raise effective_rate (pre=$preShockRate post=$postShockRate)"
    }

    $hasDispersion = $false
    $hasArbitrage = $false
    foreach ($line in $lines) {
        if ($line -match '"price_dispersion_grain":([1-9][0-9]*\.?[0-9]*)') { $hasDispersion = $true }
        if ($line -match '"arbitrage_signals":([1-9][0-9]*)') { $hasArbitrage = $true }
    }
    if (-not $hasDispersion) { throw "Golden run produced no regional grain price dispersion" }
    if (-not $hasArbitrage) { throw "Golden run produced no spatial arbitrage signals" }

    $Html = Join-Path $ReportDir "austrian_abm_report.html"
    if (-not (Test-Path $Html)) { throw "Missing austrian_abm_report.html" }

    Write-Host "Golden run passed. Log: $Jsonl ($($lines.Count) steps), report: $Html"
} finally {
    Pop-Location
}