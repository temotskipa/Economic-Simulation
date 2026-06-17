# Multi-seed experiment runner (Phase 6)
param(
    [string]$BuildDir = "build",
    [string]$Config = "Release",
    [string]$SeedList = "42,43,44",
    [int]$Steps = 12
)

$Seeds = $SeedList.Split(",") | ForEach-Object { [int]$_.Trim() }

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Exe = Join-Path $RepoRoot "$BuildDir/bin/$Config/austrian_abm.exe"

if (-not (Test-Path $Exe)) {
    Write-Error "Executable not found: $Exe. Build first."
}

$ReportBase = Join-Path $RepoRoot "reports-experiments"
New-Item -ItemType Directory -Force -Path $ReportBase | Out-Null

$env:AUSTRIAN_ABM_GOOD_STAGES = "2"
$env:AUSTRIAN_ABM_GRID_WIDTH = "224"
$env:AUSTRIAN_ABM_GRID_HEIGHT = "224"
$env:AUSTRIAN_ABM_OCCUPANCY = "0.1"
$env:AUSTRIAN_ABM_CATALOG_PATH = (Join-Path $RepoRoot "data/vic3_catalog.json")

$summary = @()
Push-Location $RepoRoot
try {
    foreach ($seed in $Seeds) {
        $reportDir = Join-Path $ReportBase "seed-$seed"
        if (Test-Path $reportDir) { Remove-Item -Recurse -Force $reportDir }
        $env:AUSTRIAN_ABM_REPORT_DIR = $reportDir

        Write-Host "Running seed=$seed steps=$Steps ..."
        & $Exe --steps $Steps --seed $seed
        if ($LASTEXITCODE -ne 0) {
            throw "Simulation failed for seed $seed (exit $LASTEXITCODE)"
        }

        $jsonl = Join-Path $reportDir "market_history.jsonl"
        $lines = Get-Content $jsonl
        $totalTrades = 0
        $maxDispersion = 0.0
        $maxArbitrage = 0
        foreach ($line in $lines) {
            if ($line -match '"trades_count":(\d+)') { $totalTrades += [int]$Matches[1] }
            if ($line -match '"price_dispersion_grain":([0-9.]+)') {
                $d = [double]$Matches[1]
                if ($d -gt $maxDispersion) { $maxDispersion = $d }
            }
            if ($line -match '"arbitrage_signals":(\d+)') {
                $a = [int]$Matches[1]
                if ($a -gt $maxArbitrage) { $maxArbitrage = $a }
            }
        }
        $summary += [pscustomobject]@{
            Seed = $seed
            Steps = $lines.Count
            TotalTrades = $totalTrades
            MaxPriceDispersion = $maxDispersion
            MaxArbitrageSignals = $maxArbitrage
            ReportDir = $reportDir
        }
    }
} finally {
    Pop-Location
}

$summary | Format-Table -AutoSize
Write-Host "Experiment complete. Reports under $ReportBase"