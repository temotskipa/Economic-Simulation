# Build and run host-only unit tests (no GPU required).
param(
    [string]$BuildDir = "out/build/ninja-debug"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $RepoRoot
try {
    cmake --build $BuildDir --target test_marginal_utility
    $Bin = Join-Path $RepoRoot "$BuildDir/bin/Debug"
    & (Join-Path $Bin "test_marginal_utility.exe")
    Write-Host "All unit tests passed."
} finally {
    Pop-Location
}