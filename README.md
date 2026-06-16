# Agent-Based Economic Simulation (Austrian ABM)

FLAME GPU 2 simulation of a decentralized market process grounded in **Austrian economics** and **methodological individualism**. Macro outcomes — prices, trade volumes, capital allocation — emerge from the independent plans and actions of heterogeneous agents. There is no top-down equilibrium solver; the market discovers coordination through subjective valuations, entrepreneurial alertness, and price signals.

## Theoretical Foundation

The model follows core Austrian principles:

- **Subjective value**: Each consumer holds a personal reservation price derived from cash, time preference, and satiation.
- **Entrepreneurial discovery**: Producers vary in alertness and adjust ask prices from local cost structures and observed market signals.
- **Roundabout production**: Capital and productivity jointly determine output; inventory and scarcity feed back into pricing.
- **Market process**: A clearing price evolves step-by-step from aggregate bid/ask pressure, not from a Walrasian auctioneer.

## Agent Populations (Phase 0)

| Agent | Role |
|-------|------|
| `consumer` | Holds cash and goods; plans purchases from subjective marginal utility |
| `producer` | Holds capital and inventory; produces goods and sets ask prices |

## Model Flow

1. **Init**: Host functions seed consumers and producers with heterogeneous endowments and preferences.
2. **Production**: Producers generate output from capital × productivity.
3. **Pricing**: Entrepreneurs set ask prices using unit cost, inventory, alertness, and the current market signal.
4. **Planning**: Consumers compute reservation prices and desired quantities.
5. **Trade**: Consumers execute trades against the emergent clearing price.
6. **Market step** (host): Aggregate demand and supply update `CLEARING_PRICE`; process repeats.

## Defaults

| Parameter | Default |
|-----------|---------|
| Consumers | `100,000` |
| Producers | `500` |
| Market steps | `12` |
| Initial clearing price | `1.0` |
| Random seed | `42` |

## Build

Requirements match standard FLAME GPU 2 native C++ on Windows:

- CMake `>= 3.25.2`
- Visual Studio 2026 with C++ and CMake support
- CUDA toolkit compatible with your host compiler (e.g., CUDA 13.2)
- NVIDIA GPU supported by the selected CUDA version

Open **Developer PowerShell for VS 2026**, change to the repository root, and run:

```powershell
cmake -S . -B out/build/ninja-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug `
  -DCMAKE_CUDA_COMPILER="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.2/bin/nvcc.exe"
cmake --build out/build/ninja-debug --target austrian_abm_simulation
```

Visual Studio's integrated CMake flow can also generate `out/build/x64-Debug`.

## Run

```powershell
.\out\build\ninja-debug\bin\Debug\austrian_abm_simulation.exe
```

Reduced debug run:

```powershell
$env:AUSTRIAN_ABM_CONSUMERS = "5000"
$env:AUSTRIAN_ABM_PRODUCERS = "200"
$env:AUSTRIAN_ABM_MARKET_STEPS = "6"
.\out\build\ninja-debug\bin\Debug\austrian_abm_simulation.exe
```

## Environment Overrides

| Variable | Description |
|----------|-------------|
| `AUSTRIAN_ABM_CONSUMERS` | Consumer population |
| `AUSTRIAN_ABM_PRODUCERS` | Producer population |
| `AUSTRIAN_ABM_MARKET_STEPS` | Simulation steps |
| `AUSTRIAN_ABM_SEED` | Random seed (alias: `AUSTRIAN_ABM_RANDOM_SEED`) |
| `AUSTRIAN_ABM_INITIAL_PRICE` | Starting clearing price |
| `AUSTRIAN_ABM_REPORT_DIR` | Report output directory (default: `reports/`) |

## Testing

Host-only unit tests (no GPU):

```powershell
pwsh -File tests/run_unit_tests.ps1
```

Smoke test (reduced population):

```powershell
pwsh -File tests/smoke/run_small_sim.ps1
```

## Output

The executable prints market-step summaries to stdout (price, demand, supply, population counts). Structured HTML/JSON reports are planned in Phase 2 — see [docs/plans/initial-plan.md](docs/plans/initial-plan.md).

## Project Layout

```
src/
  main.cu                 Entry point
  model/                  FLAME GPU model definition and agent functions
  host/                   Host step functions (market clearing)
  io/                     Config parsing
  domain/                 Pure economic logic (marginal utility)
  data/                   Constants
  util/                   Shared math helpers
tests/                    Unit and smoke tests
docs/plans/               Implementation roadmap
cmake/                    FLAME GPU fetch logic
```

## Roadmap

See [docs/plans/initial-plan.md](docs/plans/initial-plan.md) for phased expansion: capital markets, roundabout production chains, money/credit, and structured reporting.

## Related Projects

Configuration and build patterns follow [Wisconsin-PR-Simulation](https://github.com/temotskipa/Wisconsin-PR-Simulation) — a FLAME GPU 2 agent-based political simulation using the same modular `src/` layout and CMake integration.