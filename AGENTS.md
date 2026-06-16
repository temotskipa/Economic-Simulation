# AGENTS.md — Austrian ABM Simulation

Operational guidance for AI coding agents. Human contributors should start with [README.md](README.md).

**Active plan:** [docs/plans/initial-plan.md](docs/plans/initial-plan.md)

## Stack

- **Language:** C++20 / CUDA (modular layout under `src/`)
- **Framework:** [FLAME GPU 2](https://github.com/FLAMEGPU/FLAMEGPU2) `master` branch tip (updated on each CMake configure)
- **Build:** CMake ≥ 3.25.2, Ninja or Visual Studio
- **Platform:** Windows + NVIDIA GPU + CUDA 13.x (e.g. 13.2 with VS 2026)

## Key Commands

Open **Developer PowerShell for VS 2026** from the repo root.

```powershell
# Configure (Ninja debug)
cmake -S . -B out/build/ninja-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug `
  -DCMAKE_CUDA_COMPILER="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.2/bin/nvcc.exe"

# Build
cmake --build out/build/ninja-debug --target austrian_abm_simulation

# Small debug run
$env:AUSTRIAN_ABM_CONSUMERS = "5000"
$env:AUSTRIAN_ABM_PRODUCERS = "200"
$env:AUSTRIAN_ABM_MARKET_STEPS = "6"
.\out\build\ninja-debug\bin\Debug\austrian_abm_simulation.exe
```

Visual Studio CMake output also works: `out/build/x64-Debug/bin/Debug/austrian_abm_simulation.exe`

Smoke test:

```powershell
pwsh -File tests/smoke/run_small_sim.ps1
```

Unit tests (no GPU):

```powershell
pwsh -File tests/run_unit_tests.ps1
```

## Non-Obvious Patterns

### Modular layout

Simulation logic is split under `src/model/` (agents, init, `build_model.cu`), `src/host/` (market clearing), `src/io/`, `src/domain/`, and `src/data/`. `src/main.cu` is the entry point only. Cross-TU FLAME GPU symbols are declared in `src/model/model_symbols.cuh` via `*_DECL` macros.

### Austrian economics constraints

- **No equilibrium enforcement.** Prices emerge from bid/ask pressure in `AdvanceMarket`; do not add a solver that forces market clearing each step.
- **Subjective value lives on agents.** Consumer reservation prices come from `SubjectiveReservationPrice()` in `domain/marginal_utility.cuh`, not from a global utility function.
- **Heterogeneity is mandatory.** Seed functions randomize preferences, capital, and alertness. Avoid collapsing agents into representative types.
- **Entrepreneurial discovery** is modeled via per-producer `alertness` affecting ask prices, not via omniscient price-setting.

### FLAME GPU agent functions

- Agent logic uses `FLAMEGPU_AGENT_FUNCTION` / `FLAMEGPU_INIT_FUNCTION` / `FLAMEGPU_HOST_FUNCTION` macros.
- Device-safe helpers must be marked `FLAMEGPU_HOST_DEVICE_FUNCTION`.
- Layers run in order defined in `BuildModel()`; host functions after agent functions in a layer see updated agent state from the same step.

### Environment properties vs env vars

Runtime config is read at model build time via `getenv` in `BuildModel()`. Code uses:

| Env var (code) | README alias (also accept) |
|----------------|----------------------------|
| `AUSTRIAN_ABM_SEED` | `AUSTRIAN_ABM_RANDOM_SEED` |

Other vars: `AUSTRIAN_ABM_CONSUMERS`, `AUSTRIAN_ABM_PRODUCERS`, `AUSTRIAN_ABM_MARKET_STEPS`, `AUSTRIAN_ABM_INITIAL_PRICE`, `AUSTRIAN_ABM_REPORT_DIR`.

### Host step pulls agent data

`AdvanceMarket` pulls full consumer and producer populations each step to compute aggregate demand/supply and update `CLEARING_PRICE`. Keep host pulls bounded; prefer GPU macro properties for tallies once populations exceed ~100k.

## Code Style

- Namespace: `austrian_abm`
- Match existing naming: `k` prefix for constants, `ClampFloat` for bounds
- Prefer focused diffs; no drive-by refactors unrelated to the task
- Do not add verbose comments on obvious code
- CUDA agent functions: keep stack usage bounded; no unbounded agent arrays

## Testing Rules

- Add or update tests when changing `domain/marginal_utility.cuh` or config parsing.
- For behavior-preserving refactors, capture a **golden run** (fixed seed, reduced population) and compare stdout price series.
- Run smoke test after agent-function or host-function changes.
- Run unit tests before committing domain logic changes.

## Boundaries

### Allowed without asking

- Read and edit `src/`, `CMakeLists.txt`, `docs/`, `tests/`
- Run cmake build and small simulation executables
- Add host-only unit tests under `tests/`

### Ask first

- Changing `FLAMEGPU_VERSION` or `FLAMEGPU_REPOSITORY` in `CMakeLists.txt`
- Enabling `FLAMEGPU_VISUALISATION`
- Adding new dependencies or FetchContent repos
- Changing default population sizes or core economic semantics
- Introducing central-planning or equilibrium-solver mechanics

### Never

- Commit secrets, `.env` files, or API keys
- Force-push to `main` / `master`
- Edit fetched FLAME GPU sources under build `_deps/`
- Add Walrasian auctioneer or representative-agent shortcuts that bypass individual plans
- Auto-generate or bulk-expand this file with README duplicates (keep concise; see [agents.md](https://agents.md/))

## Key Files

| File | Role |
|------|------|
| `src/main.cu` | Entry point (`RunMain`) |
| `src/model/build_model.cu` | Model description, layers, init/step registration |
| `src/model/model_symbols.cuh` | `FLAMEGPU_*_DECL` forward declarations for split TUs |
| `src/host/step_advance_market.cu` | Price discovery from aggregate bid/ask |
| `src/domain/marginal_utility.cuh` | Subjective value and entrepreneurial pricing |
| `CMakeLists.txt` | Build config, `ALL_SRC` list |
| `cmake/flamegpu2.cmake` | FLAME GPU fetch/find logic |
| `README.md` | Human docs: theory, build, env vars |
| `docs/plans/initial-plan.md` | Implementation roadmap |

## PR Guidance

- One phase or sub-PR per plan section when possible.
- Behavior-preserving splits: golden-run proof required.
- Update `docs/plans/initial-plan.md` status when completing a phase.
- Keep AGENTS.md updated only when commands, layout, or non-obvious patterns change.