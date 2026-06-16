# Austrian ABM Simulation (Sugarscape)

GPU-accelerated agent-based economic simulation built on the **FLAME GPU 2 Sugarscape** foundation. Prices, trade, wealth, and spatial resource dynamics emerge from heterogeneous agents with subjective reservation prices and decentralized matching — no central equilibrium solver.

## Foundation

Ported from the official FLAME GPU 2 Sugarscape C++ example, extended with:

- **Sugar + spice** regenerating resource patches on a 2D grid
- **Money** as medium of exchange
- **Decentralized trade** via reservation-price bids/asks and host-side matching
- **Market logging** to `market_history.jsonl`

## Model Flow

1. **Metabolise & growback** — occupied cells harvest resources; metabolism consumes sugar then spice; empty patches regenerate.
2. **Movement submodel** — agents move toward higher combined sugar/spice using conflict-resolution submodel.
3. **Trade offers** — occupied agents post subjective bids/asks (MRS-based) via `MessageBruteForce`.
4. **Match trades** (host) — crossing bids/asks execute; money and inventories update.
5. **Log step** (host) — append price, volume, Gini, population to `market_history.jsonl`.

## Golden Run

seed=42, 224×224 grid, 10% occupancy (~5000 agents), 12 steps:

```powershell
cmake -B build -S . -G "Visual Studio 17 2022" -A x64 -DCMAKE_CUDA_ARCHITECTURES=89
cmake --build build --config Release -j $env:NUMBER_OF_PROCESSORS
$env:AUSTRIAN_ABM_GOOD_STAGES="2"
.\build\bin\Release\austrian_abm.exe --steps 12 --seed 42
```

Or use the smoke script:

```powershell
pwsh -File tests/smoke/run_golden_run.ps1
```

## Environment Overrides

| Variable | Default | Description |
|----------|---------|-------------|
| `AUSTRIAN_ABM_GRID_WIDTH` | `224` | Grid width |
| `AUSTRIAN_ABM_GRID_HEIGHT` | `224` | Grid height |
| `AUSTRIAN_ABM_OCCUPANCY` | `0.1` | Fraction of cells with agents |
| `AUSTRIAN_ABM_INITIAL_MONEY` | `100` | Starting money balance |
| `AUSTRIAN_ABM_GOOD_STAGES` | `2` | Production stages (Phase 2+) |
| `AUSTRIAN_ABM_REPORT_DIR` | `reports/` | Log output directory |
| `AUSTRIAN_ABM_SEED` | `42` | Random seed (alias: `AUSTRIAN_ABM_RANDOM_SEED`) |

CLI flags: `--steps N`, `--seed N`

## Output

- **Stdout** — trade summaries when `TRADES_COUNT > 0`
- **`market_history.jsonl`** — per-step avg price, trade volume, wealth Gini, population, total sugar/spice

## Roadmap

See [docs/plans/initial-plan.md](docs/plans/initial-plan.md) for Phases 2–6 (reports, production chains, capital, banking, spatial enhancement, CI).