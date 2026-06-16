# AGENTS.md — Austrian ABM Simulation

Operational guidance for AI coding agents. Human contributors start with [README.md](README.md).

**Active plan:** [docs/plans/initial-plan.md](docs/plans/initial-plan.md)

## Stack

- **Language:** C++20 / CUDA (modular `src/` layout)
- **Framework:** [FLAME GPU 2](https://github.com/FLAMEGPU/FLAMEGPU2) `master`
- **Foundation:** Sugarscape port (grid cells + movement submodel)
- **Build:** CMake ≥ 3.25.2, Visual Studio 2022, CUDA 13.x, sm_89
- **Platform:** Windows 11 + RTX 4070 Ti class GPU

## Key Commands

```powershell
cmake -B build -S . -G "Visual Studio 17 2022" -A x64 -DCMAKE_CUDA_ARCHITECTURES=89
cmake --build build --config Release -j $env:NUMBER_OF_PROCESSORS

$env:AUSTRIAN_ABM_GOOD_STAGES = "2"
.\build\bin\Release\austrian_abm.exe --steps 12 --seed 42

pwsh -File tests/smoke/run_golden_run.ps1
```

First build must compile `flamegpu` target (~5 min). Subsequent builds are incremental.

## Layout

| Path | Role |
|------|------|
| `src/domain/cell_functions.cu` | Metabolise + growback (sugar/spice) |
| `src/domain/movement_functions.cu` | Movement submodel + exit condition |
| `src/domain/trade_functions.cu` | `OutputTradeOffers` (MessageBruteForce) |
| `src/domain/trade_functions.cuh` | MRS / reservation price math |
| `src/host/seed_grid.cu` | Grid + hotspot initialization |
| `src/host/step_match_trades.cu` | Decentralized trade matching + logging step |
| `src/host/step_log.cpp` | `market_history.jsonl` writer |
| `src/model/build_model.cu` | Model layers, submodel, env properties |

## Non-Obvious Patterns

### Sugarscape cell agents

One `cell` agent per grid position. Person state lives on occupied cells (`agent_id`, `sugar_level`, `spice_level`, `money`). Do not add a separate person agent type without updating movement submodel bindings.

### Movement submodel

Conflict resolution runs in `movement_conflict_resolution` submodel with `MessageArray2D`. Preserve exit condition `MovementExitCondition` (max 9 iterations).

### Trade flow

1. `OutputTradeOffers` sets bid/ask agent variables + one `trade_offer` message.
2. `MatchTrades` reads population, matches crossing bids/asks, calls `setPopulationData`.
3. `LogMarketStep` appends JSONL after matching.

Host matching uses agent variables, not message iteration — messages exist for future decentralized matching.

### Austrian constraints

- No Walrasian auctioneer or equilibrium solver.
- Reservation prices from local MRS (`trade_functions.cuh`).
- Heterogeneous endowments from `SeedGrid` hotspots.

### Env vars vs CLI

`ParseSimulationConfig()` merges env vars and `--steps` / `--seed` CLI flags.

## Testing Rules

- Run golden run after agent-function, host-function, or trade-logic changes.
- Confirm `market_history.jsonl` has 12 lines and at least one `trades_count > 0`.
- Use reduced grid for quick debug: `$env:AUSTRIAN_ABM_GRID_WIDTH="64"`.

## Boundaries

### Allowed without asking

- Edit `src/`, `CMakeLists.txt`, `docs/`, `tests/`
- Run Release build and golden run

### Ask first

- Changing `FLAMEGPU_VERSION`, enabling visualisation
- Replacing movement submodel pattern
- Adding equilibrium solvers or representative-agent shortcuts

### Never

- Commit secrets or edit `_deps/` FLAME GPU sources
- Force-push `main`/`master`
- Reintroduce the old consumer/producer scaffold (removed in Phase 1)

## PR Guidance

- One plan task per PR when possible.
- Update plan checkboxes when completing phases.
- Golden-run proof required for trade or movement changes.