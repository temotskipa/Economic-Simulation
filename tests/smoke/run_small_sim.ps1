# Smoke test: build and run a reduced simulation.
param(
    [string]$BuildDir = "out/build/ninja-debug"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")

$Exe = Join-Path $RepoRoot "$BuildDir/bin/Debug/austrian_abm_simulation.exe"
if (-not (Test-Path $Exe)) {
    Write-Error "Executable not found: $Exe. Build first with cmake --build $BuildDir --target austrian_abm_simulation"
}

$env:AUSTRIAN_ABM_CONSUMERS = "5000"
$env:AUSTRIAN_ABM_PRODUCERS = "200"
$env:AUSTRIAN_ABM_MARKET_STEPS = "6"
$env:AUSTRIAN_ABM_SEED = "42"

Push-Location $RepoRoot
try {
    & $Exe
    if ($LASTEXITCODE -ne 0) {
        throw "Simulation exited with code $LASTEXITCODE"
    }
    Write-Host "Smoke test passed."
} finally {
    Pop-Location
}