# Implementation Plan: C Algorithm Parity Testing

**Branch**: `005-c-algo-parity` | **Date**: 2025-12-12 | **Spec**: [specs/005-c-algo-parity/spec.md](specs/005-c-algo-parity/spec.md)
**Input**: Feature specification from `/specs/005-c-algo-parity/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Parity harness to feed a shared corpus into two C builds—the canonical C core in `Sources/CColorJourney` (baseline) and the wasm-target C sources compiled as plain C (target)—producing deterministic reports with per-case deltas, provenance, and reproducible artifacts. Outputs normalize into a common representation (OKLab-driven) with configurable tolerances, aggregated summaries, and CI-friendly execution hooks. No Node/TypeScript runtime is required; optional Python may postprocess stats from C-emitted JSON.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: C99 core (Sources/CColorJourney), Swift 5.9 wrapper; wasm-target sources compiled as C for parity.  
**Primary Dependencies**: SwiftPM with `swift-docc-plugin`; clang/gcc for C harness; pinned cJSON for JSON parsing; optional Python 3.x for statistics postprocessing.  
**Storage**: Filesystem artifacts (reports, corpus snapshots, diff payloads); no persistent DB.  
**Testing**: C harness via `make test-c` plus parity-runner C unit/integration tests (JSON validation, tolerances, comparison, deterministic fixture run); XCTest for Swift wrapper; optional Python stats script consumes C-emitted JSON.  
**Target Platform**: macOS CI runner (primary), portable C99 builds; CI treats C core as canonical output reference.  
**Project Type**: Library (C core + Swift wrapper) with C parity test harness and reporting pipeline.  
**Performance Goals**: Default corpus completes in ≤10 minutes (SC-001); per-case comparison tolerances align with perceptual fidelity while avoiding false positives; parity harness overhead does not regress core performance benchmarks  
**Constraints**: Deterministic outputs (seeded runs), OKLab/double-precision normalization, identical build flags captured in provenance, minimal external dependencies for C99 portability  
**Scale/Scope**: Corpus breadth to cover typical palettes + boundary values; versioned JSON fixtures under `specs/005-c-algo-parity/corpus` with growth over time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Universal Portability**: C99 core remains canonical; wasm parity uses C output as ground truth. Plan complies—no divergence allowed. Status: PASS.
- **Perceptual Integrity (OKLab, double precision)**: Comparisons must normalize to OKLab/double precision before diffing to avoid space drift. Status: PASS with enforcement in data model/contracts.
- **Deterministic Output**: Parity harness must use seeded, reproducible runs with build flags captured. Status: PASS contingent on provenance capture and fixed seeds.
- **Comprehensive Testing**: Parity suite adds mandatory coverage for cross-implementation drift and regression artifacts. Status: PASS; to be re-validated after design.

Post-Phase 1 check: All gates remain satisfied; OKLab normalization, provenance capture, and deterministic seeds are embedded in the data model/contracts.

## Project Structure

### Documentation (this feature)

```text
specs/005-c-algo-parity/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Sources/
├── CColorJourney/        # Canonical C99 core (ColorJourney.c, include/)
├── ColorJourney/         # Swift wrapper bridging to C core
├── wasm/                 # wasm-target C sources, build-wasm.sh

Examples/                 # C and Swift usage demos
Tests/                    # Swift (XCTest) and C tests (make test-c)
Docs/, DevDocs/           # Generated docs and development guides
scripts/                  # release/build helpers
```

**Structure Decision**: Single library codebase (C core + Swift wrapper) with wasm build path; parity harness will live under `specs/005-c-algo-parity` docs plus test/CLI assets co-located with existing test tooling (XCTest + C harness) to preserve portability.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
