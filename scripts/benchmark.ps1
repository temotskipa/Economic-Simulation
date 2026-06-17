# GPU performance benchmark (Phase 6) — large grid, timed run
param(
    [string]$BuildDir = "build",
    [string]$Config = "Release",
    [int]$Steps = 24,
    [int]$Seed = 42,
    [int]$GridSize = 512
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Exe = Join-Path $RepoRoot "$BuildDir/bin/$Config/austrian_abm.exe"

if (-not (Test-Path $Exe)) {
    Write-Error "Executable not found: $Exe. Build first."
}

$ReportDir = Join-Path $RepoRoot "reports-benchmark"
if (Test-Path $ReportDir) { Remove-Item -Recurse -Force $ReportDir }

$env:AUSTRIAN_ABM_GOOD_STAGES = "2"
$env:AUSTRIAN_ABM_REPORT_DIR = $ReportDir
$env:AUSTRIAN_ABM_GRID_WIDTH = "$GridSize"
$env:AUSTRIAN_ABM_GRID_HEIGHT = "$GridSize"
$env:AUSTRIAN_ABM_OCCUPANCY = "0.1"
$env:AUSTRIAN_ABM_CATALOG_PATH = (Join-Path $RepoRoot "data/vic3_catalog.json")

$agentEstimate = [int]($GridSize * $GridSize * 0.1)
Write-Host "Benchmark: ${GridSize}x${GridSize} grid (~$agentEstimate agents), $Steps steps, seed=$Seed"

Push-Location $RepoRoot
try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $Exe --steps $Steps --seed $Seed
    $sw.Stop()
    if ($LASTEXITCODE -ne 0) {
        throw "Benchmark run failed (exit $LASTEXITCODE)"
    }

    $msPerStep = [math]::Round($sw.ElapsedMilliseconds / $Steps, 1)
    Write-Host "Elapsed: $($sw.Elapsed.TotalSeconds.ToString('F2'))s ($msPerStep ms/step)"
    Write-Host "Log: $(Join-Path $ReportDir 'market_history.jsonl')"
} finally {
    Pop-Location
}