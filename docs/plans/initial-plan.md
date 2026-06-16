# Austrian ABM Simulation — Direct Implementation Instructions for Grok Composer 2.5 Fast

**Version:** 3.1 — Sugarscape Extension Foundation (Revised)  
**Date:** 2026-06-17  
**Target Environment:** Windows 11, CUDA 13.x, RTX 4070 Ti (sm_89), Visual Studio 2022  
**Framework:** FLAME GPU 2 (C++ template)  
**Primary Model:** You are Grok Composer 2.5 Fast running inside Grok Build  
**Foundation:** Port + Extend existing FLAME GPU 2 Sugarscape implementation  
**Objective:** Build a decentralized, emergent market-process economic simulation on top of Sugarscape where prices, capital structure, trade, wealth dynamics, and business cycles arise strictly from heterogeneous agent rules and local interactions. No central clearing or imposed equilibrium.

---

## Your Role & Strict Operating Rules

You are the coding agent. Your job is to implement by editing files, running builds/tests via tools, verifying after every task, and reporting results.

**Mandatory Rules:**
- Work **one task at a time** in exact order.
- After **every task** you **must** run the verification command(s), report output, and only proceed if it passes.
- Never skip verification.
- Use exact file paths and names specified.
- Keep all changes minimal and clean for Windows + CUDA 13.
- Show diffs or changed lines when editing.
- Fix build/test failures before moving on.
- Use PowerShell commands and Windows paths.
- Leverage sub-agents for parallel work when useful (e.g., device functions vs host logic).
- Maintain `austrian_abm` namespace and `AUSTRIAN_ABM_*` env vars.
- All economic behavior must be local and subjective.

**Golden Run (use for major verifications):** seed=42, 5000 agents, 12 steps. Snapshot logs or `market_history.jsonl`.

---

## Environment & Constraints

- Windows 11 + Visual Studio 2022 + CUDA 13 (sm_89).
- Use these exact commands:
  ```powershell
  cmake -B build -S . -G "Visual Studio 17 2022" -A x64 -DCMAKE_CUDA_ARCHITECTURES=89
  cmake --build build --config Release -j $env:NUMBER_OF_PROCESSORS
  $env:AUSTRIAN_ABM_GOOD_STAGES="2"; .\build\bin\Release\austrian_abm.exe --steps 12 --seed 42
  ```
- Existing Wisconsin-PR layout and any current scaffold must be respected or cleanly integrated.
- You may create files in `src/domain/`, `src/host/`, `src/model/`, `src/io/`, `src/data/`, `tests/`, `scripts/`.
- Device functions → `src/domain/*.cuh`
- Host logic → `src/host/`

**Sugarscape Foundation (already exists in FLAME GPU 2):**
- Discrete grid of regenerating resource patches (sugar + spice)
- Mobile agents with vision, metabolism, movement to higher resources
- Basic bilateral trade when MRS differs
- Submodel pattern for resolving simultaneous claims on patches (critical for future matching)
- Scales to millions of agents

Your job is to **port/adapt** this into the project and then extend it.

---

## Overall Workflow

1. Read phase and tasks.
2. Implement tasks in listed order.
3. After each task: run verification, report result, only continue on success.
4. At end of phase: run golden run + phase exit checks.
5. Suggest Git commit.
6. Only advance after confirming all exit criteria.

---

## Phase 1 — Port & Extend Sugarscape with Decentralized Money-Mediated Trade

**Goal:** Bring the working FLAME GPU 2 Sugarscape into the project and extend it with money as a medium of exchange + proper decentralized reservation-price trading. This replaces any minimal scaffold and gives immediate spatial economics + emergent trade.

### Tasks (in exact order)

**Task 1.1 — Port Sugarscape base into the project**  
- Reference the official FLAME GPU 2 Sugarscape Python tutorial and the C++ description in the 2023 paper.
- Create/adapt the core files:
  - Patch/resource agents (regenerating sugar + spice on a grid)
  - Person/agent with vision, metabolism, position, inventory (sugar, spice), wealth
  - Movement logic using existing submodel pattern for conflict resolution
  - Basic metabolism and death/reproduction
- Integrate into `src/model/model.cu`, `src/domain/`, and `src/host/`.
- Make it compile and run a basic 12-step simulation.

**Verification:** Clean Release build + golden run completes without crash. Agents move and resources regenerate.

**Task 1.2 — Add money balances and environment properties**  
Extend agents with a `money` variable (or deposits).  
Add environment properties for initial money distribution, trade radius, etc.

**Verification:** Build succeeds and agents can hold money.

**Task 1.3 — Implement decentralized trade offers (money-mediated)**  
Create `src/domain/trade_functions.cuh` with:
- `OutputTradeOffers` — agents post reservation-price bids/asks for sugar/spice using money (based on marginal utility / MRS).
- Use `MessageBruteForce` or `MessageSpatial2D` (start with BruteForce for simplicity).

Register the functions in the correct layer after movement/metabolism.

**Verification:** Build succeeds. Agents output trade messages.

**Task 1.4 — Implement trade matching & execution**  
Create `src/host/step_match_trades.cu` (recommended for Phase 1):
- Read trade offers.
- Match crossing bids/asks (simple price-based or random for MVP).
- Execute trades by updating money + inventory on both agents.
- Log `TRADES_COUNT` and volume-weighted price.

Wire into the simulation loop.

**Verification:** Golden run produces `TRADES_COUNT > 0` and varying effective prices. Report sample trade data.

**Task 1.5 — Add basic logging**  
Implement step logger writing `market_history.jsonl` with step, average price, trade volume, wealth Gini, population, total sugar/spice.

**Verification:** Log file is produced with meaningful data after golden run.

**Phase 1 Exit Criteria (confirm all):**
- Clean build on Windows + CUDA 13.
- Golden run completes.
- Agents trade using money and `TRADES_COUNT > 0`.
- `market_history.jsonl` exists with real data.
- Spatial movement + resource regeneration still works.

---

## Phase 2 — Observability & Multi-Good Production

**Goal:** Improve visibility and begin adding production chains on top of the Sugarscape foundation.

**Tasks:**
- Enhance HTML report generator (`src/io/report_html.cu`) showing wealth distribution, trade networks, resource maps if possible.
- Add simple production recipes (e.g., combining sugar + spice into higher-utility “food”).
- Extend agents with production activity choice based on local prices and skills.

**Phase 2 Exit Criteria:** Richer reports + basic production activity visible in logs/golden run.

---

## Phase 3 — Capital, Roundabout Production & Time Preference

**Goal:** Introduce capital goods, multi-stage production, and capital owners who save/invest according to time preference.

**Key additions (build on Sugarscape agents):**
- New or extended `capital_owner` behavior.
- Capital goods that boost production efficiency.
- Present-value calculations (`src/domain/present_value.cuh`).
- Investment decisions based on expected returns vs time preference.
- Multi-stage production (raw resources → intermediate → final goods).

**Implementation order:** Data structures → capital mechanics → investment functions → update golden run → verify capital accumulation and differential production periods.

**Phase 3 Exit Criteria:** Capital owners allocate savings, longer production processes appear when profitable, golden run shows capital stock growth.

---

## Phase 4 — Money, Credit & Austrian Business Cycle

**Goal:** Add banking and credit creation with maturity transformation. Enable interest rate shocks to demonstrate ABCT-style effects on top of the Sugarscape economy.

**Key additions:**
- `bank` agent type with reserves, deposits, loans.
- Loan market between entrepreneurs and banks.
- Environment variable for artificial rate suppression.
- Observation of malinvestment (excessive funding of longer production periods).

**Phase 4 Exit Criteria:** Banks create credit, a rate shock changes capital structure, effects visible in logs.

---

## Phase 5 — Spatial Enhancement & Regional Heterogeneity (Optional)

Further leverage and extend Sugarscape’s spatial nature with `MessageSpatial2D`, regional productivity differences, and observable price dispersion/arbitrage.

---

## Phase 6 — Validation, Experiments & CI

Add experiment scripts, performance benchmarks on your 4070 Ti (aim for large agent counts thanks to Sugarscape scaling), and basic sanity checks.

---

## Architecture Constraints

- Preserve and extend the Sugarscape execution flow (resource growth → movement → metabolism/trade → demographics).
- Use message passing for all agent interaction.
- Use submodels for conflict resolution (movement or matching) as demonstrated in the original Sugarscape FLAME GPU 2 implementation.
- Keep decisions local and subjective.

---

## Verification Protocol

After every task:
1. Build with the exact CMake command.
2. Run golden run (or phase-specific test).
3. Confirm expected behavior occurred.
4. Report build status + key output.
5. Only proceed on success.

---

## Quick Reference Commands

Use the PowerShell commands listed in the Environment section for all builds and golden runs.

---

**You now have a complete, self-contained instruction set centered on porting and extending Sugarscape.**

Start by confirming understanding of the rules, then begin **Phase 1 Task 1.1** (porting the Sugarscape base). Report the result after verification, then continue.

When you need the exact code for any task (e.g., “Implement Task 1.3 — trade offers on Sugarscape agents”), reply with the task number and I will provide the precise implementation.

Execute. Verify. Report. Proceed.