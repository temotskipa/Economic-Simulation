# Basic sanity checks on market_history.jsonl schema (Phase 6)
param(
    [string]$JsonlPath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")

if (-not $JsonlPath) {
    $JsonlPath = Join-Path $RepoRoot "reports-golden/market_history.jsonl"
}

if (-not (Test-Path $JsonlPath)) {
    Write-Error "JSONL not found: $JsonlPath. Run golden run first."
}

$requiredFields = @(
    "step", "avg_price", "trades_count", "trade_volume", "wealth_gini",
    "population", "total_sugar", "total_spice", "total_food",
    "total_res", "total_ind", "total_tech",
    "production_count", "total_capital", "credit_created",
    "effective_rate", "price_dispersion_grain", "arbitrage_signals"
)

$lines = Get-Content $JsonlPath
if ($lines.Count -lt 1) { throw "Empty JSONL: $JsonlPath" }

$lineNum = 0
foreach ($line in $lines) {
    ++$lineNum
    foreach ($field in $requiredFields) {
        if ($line -notmatch "`"$field`":") {
            throw "Line $lineNum missing field '$field'"
        }
    }
    if ($line -match '"population":0[,}]') {
        throw "Line $lineNum has zero population"
    }
}

Write-Host "Sanity checks passed ($($lines.Count) lines, $($requiredFields.Count) required fields)"