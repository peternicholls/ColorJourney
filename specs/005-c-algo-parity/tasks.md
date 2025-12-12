---

description: "Tasks for C Algorithm Parity Testing"
---

# Tasks: C Algorithm Parity Testing

**Input**: Design documents from `/specs/005-c-algo-parity/`
**Prerequisites**: plan.md (required), spec.md (user stories), research.md, data-model.md, contracts/

**Tests**: Tests are mandatory. Add C unit/integration tests alongside harness code; parity runs must be reproducible and validated.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish folders and configs needed before building the harness (pure C focus).

- [X] T001 Create corpus directory scaffold and placeholder keep-alive in specs/005-c-algo-parity/corpus/.gitkeep
- [X] T002 Add corpus JSON schema defining InputCase and config fields in specs/005-c-algo-parity/corpus/schema.json
- [X] T003 Add default tolerance/config template (abs/rel, deltaE) in specs/005-c-algo-parity/config/tolerances.example.json
- [X] T004 Document required C toolchain (clang/gcc C99) and test commands in specs/005-c-algo-parity/quickstart.md
- [X] T005 [P] Add artifacts root with README for run outputs in specs/005-c-algo-parity/artifacts/README.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core plumbing that all user stories rely on (types, validation, build inputs) in C, with optional Python for stats-only postprocessing.

- [X] T006 Initialize C parity runner workspace with Makefile (build/run/test targets) in specs/005-c-algo-parity/tools/parity-runner/
- [X] T007 [P] Define shared C headers for InputCase, EngineOutput, ComparisonResult, RunReport in specs/005-c-algo-parity/tools/parity-runner/include/types.h
- [X] T008 [P] Implement corpus and tolerance JSON parsing/validation in C in specs/005-c-algo-parity/tools/parity-runner/src/json_validation.c
- [X] T009 [P] Add C CLI entry (arg parsing for cases, tolerances, artifacts path) in specs/005-c-algo-parity/tools/parity-runner/src/main.c
- [X] T010 Vendor minimal C JSON dependency (pin cJSON) and wire Makefile to build parity-runner binary
- [X] T031 Define and publish default tolerances (abs L/a/b=1e-4, ΔE<=0.5, rel L/a/b=1e-3) plus override policy in specs/005-c-algo-parity/config/README.md and tolerances.example.json
- [X] T032 Add corpus versioning policy (`vYYYYMMDD.n`) and validation in specs/005-c-algo-parity/tools/parity-runner/src/json_validation.c and specs/005-c-algo-parity/config/README.md
- [X] T039 Add C unit tests for JSON parsing/validation, tolerances application, and OKLab comparison math in specs/005-c-algo-parity/tools/parity-runner/tests/
- [X] T040 Add C integration test that runs parity-runner against a tiny corpus and asserts deterministic pass/fail outputs in specs/005-c-algo-parity/tools/parity-runner/tests/
- [X] T041 Wire tests into Makefile (`make test`) and ensure CI target executes them before reporting success

**Checkpoint**: Foundation ready—user stories can proceed.

---

## Phase 3: User Story 1 - Parity Report For Both Engines (Priority: P1) 🎯 MVP

**Goal**: Run corpus through two C builds (canonical C core and wasm-target sources compiled as plain C), normalize outputs, and emit deterministic pass/fail report with per-case deltas.

**Independent Test**: Run the C CLI on the default corpus to produce report and summary without other stories.

### Implementation for User Story 1

- [ ] T011 [P] Add default corpus cases (baseline, boundary, seeded) in specs/005-c-algo-parity/corpus/default.json
- [ ] T012 [P] Build C reference JSON emitter binary (wrap ColorJourney.c) in Tests/Parity/parity_c_runner.c
- [ ] T013 [P] Build alternate C binary from Sources/wasm as plain C (matching flags) in Tests/Parity/parity_wasm_as_c_runner.c
- [ ] T014 [P] Implement execution wrapper for canonical C binary (spawn parity_c_runner, parse JSON) in specs/005-c-algo-parity/tools/parity-runner/src/exec_c.c
- [ ] T015 [P] Implement execution wrapper for wasm-sources-as-C binary in specs/005-c-algo-parity/tools/parity-runner/src/exec_c_alt.c
- [ ] T016 Normalize both outputs to OKLab double precision and compare with tolerances in specs/005-c-algo-parity/tools/parity-runner/src/compare.c
- [ ] T017 Generate run report with summary totals and per-case results in specs/005-c-algo-parity/tools/parity-runner/src/report.c
- [ ] T018 Wire CLI flow to run corpus, collect results, and write artifacts under specs/005-c-algo-parity/artifacts/<runId>/ in specs/005-c-algo-parity/tools/parity-runner/src/main.c
- [ ] T033 Add edge-case corpus fixtures (extremes, malformed inputs with expected rejections, platform-flag notes) in specs/005-c-algo-parity/corpus/edge-cases.json
- [ ] T034 Capture run provenance (corpus version, commits, build flags, platform) in report header and artifacts in specs/005-c-algo-parity/tools/parity-runner/src/report.c
- [ ] T035 Enforce pass-rate gate (>=95%) and fail runs below threshold in specs/005-c-algo-parity/tools/parity-runner/src/report.c
- [ ] T036 Measure total runtime; fail or flag runs exceeding 10 minutes and record duration in report summary in specs/005-c-algo-parity/tools/parity-runner/src/main.c
- [ ] T037 [P] Compute summary statistics (mean/stddev/p50/p95/p99/max) and histograms for ΔE and per-channel OKLab deltas in C; optionally export JSON for Python postprocessing in specs/005-c-algo-parity/tools/stats/

**Checkpoint**: P1 MVP delivers deterministic parity report and artifacts.

---

## Phase 4: User Story 2 - Root Cause Hints For Divergences (Priority: P2)

**Goal**: Surface top contributing differences and stage/parameter hints for failing cases.

**Independent Test**: For a failing case, report lists channel/metric magnitudes and maps to computation stage/parameter.

### Implementation for User Story 2

- [ ] T019 [P] Add stage/parameter mapping metadata (e.g., channel labels, stage names) in specs/005-c-algo-parity/tools/parity-runner/src/stage_map.c
- [ ] T020 [P] Compute per-case top contributors (OKLab components, ΔE, RGB deltas) with directionality in specs/005-c-algo-parity/tools/parity-runner/src/analysis.c
- [ ] T021 Annotate failing cases with stage/parameter hints and include in report output in specs/005-c-algo-parity/tools/parity-runner/src/report.c
- [ ] T022 Add focused artifact bundle per failing case (inputs, both outputs, deltas, hints) in specs/005-c-algo-parity/artifacts/<runId>/<caseId>/metadata.json
- [ ] T038 [P] Highlight statistically significant contributors (e.g., highest ΔE/z-score channels/stages) in failure hints in specs/005-c-algo-parity/tools/parity-runner/src/analysis.c

**Checkpoint**: P2 delivers actionable hints per failure.

---

## Phase 5: User Story 3 - Traceable Regression Prevention (Priority: P3)

**Goal**: CI/on-demand runs fail on new divergences and persist reproducible artifacts.

**Independent Test**: CI job fails on new drift and saves artifacts per failing case.

### Implementation for User Story 3

- [ ] T023 Add CLI options for corpus filters, tolerance overrides, and artifact retention policy in specs/005-c-algo-parity/tools/parity-runner/src/main.c
- [ ] T024 [P] Ensure CI workflow runs C parity binary and persists provenance (commits, build flags, platform, corpus version) alongside uploaded artifacts in .github/workflows/parity.yml
- [ ] T025 [P] Add CI workflow to run parity suite and upload artifacts on failure in .github/workflows/parity.yml
- [ ] T026 Persist artifacts directory structure with .gitkeep and README in specs/005-c-algo-parity/artifacts/.gitkeep

**Checkpoint**: P3 enables regression prevention with artifacts.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Shared improvements across stories.

- [ ] T027 [P] Update operator docs with C CLI usage and report formats in specs/005-c-algo-parity/quickstart.md
- [ ] T028 [P] Add tolerance configuration docs and examples in specs/005-c-algo-parity/config/README.md
- [ ] T029 [P] Add schema and API references to specs/005-c-algo-parity/contracts/README.md
- [ ] T030 Run end-to-end dry run over full corpus and capture sample report in specs/005-c-algo-parity/artifacts/sample-run/README.md

---

## Dependencies & Execution Order

- Setup (Phase 1) → Foundational (Phase 2) → US1 (P1) → US2 (P2) → US3 (P3) → Polish.
- US2 depends on US1 comparison outputs; US3 depends on US1 reports and US2 hint metadata.
- Parallelizable tasks marked [P] can proceed concurrently when file paths do not conflict.

## Parallel Execution Examples

- Foundation: T007, T008, T009 can run in parallel (separate C units and Makefile wiring).
- US1: T013, T014, T015 can run in parallel after T006-T009 since they build/run separate binaries.
- US2: T019 and T020 can run in parallel; T021 depends on both.
- US3: T024 and T025 can run in parallel; T023 depends on CLI base (T009, T018).

## Implementation Strategy

- MVP first: complete Setup → Foundational → US1 to get deterministic parity reports.
- Incremental: add US2 for diagnostics, then US3 for CI gating and artifact retention.
- Each story is independently testable by invoking the CLI against the corpus with its respective outputs enabled.
