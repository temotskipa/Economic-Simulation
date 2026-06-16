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

    Write-Host "Golden run passed. Log: $Jsonl ($($lines.Count) steps)"
} finally {
    Pop-Location
}