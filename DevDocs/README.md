# Developer Documentation Hub

Source of truth for ColorJourney contributors. Use this folder for accurate context, rationale, and the how-tos needed to build, test, document, and release the project.

## Start Here
- Orientation: `00_START_HERE.md` (quick pathways) → `standards/ARCHITECTURE.md` (system shape) → `QUICK_REFERENCE.md` (API usage patterns).
- Writing or publishing docs: `guides/UNIFIED_DOCS_BUILD.md`, `guides/SWIFT_DOCC_GUIDE.md`, `guides/SWIFT_DOCC_PLUGIN_GUIDE.md`, `SWIFT_DOCC_404_SOLUTION.md`.
- Shipping builds: `RELEASE_PLAYBOOK.md`, `RELEASE_GATES.md`, `RELEASE_TAGGING.md`, `RC_WORKFLOW.md`.
- Understanding rationale: `UNIVERSAL_PORTABILITY.md`, `PRD.md`, `ALGORITHM_COMPARISON_ANALYSIS.md`, `USAGE_AND_FULFILLMENT_ANALYSIS.md`.

## Current State (verified)
- Core engine: `Sources/CColorJourney/ColorJourney.c` (~867 LOC, C99, no deps beyond `-lm`).
- Swift surface: `Sources/ColorJourney/` (~885 LOC across configuration, types, SwiftUI extensions, and the umbrella doc file).
- Tests: `Tests/ColorJourneyTests/ColorJourneyTests.swift` (52 XCTest cases) plus `Tests/CColorJourneyTests/test_c_core.c` (C harness). Run `swift test` or `make test-c`.
- Docs build: `make docs`, `make docs-swift`, `make docs-c`, `make docs-validate`, `make docs-publish` (see `Makefile` targets 72–151).
- Generated docs output to `Docs/generated/swift-docc/` and `Docs/generated/doxygen/`; unified index lives in `Docs/`.

## Document Map
- **Foundations & Vision**
  - `PRD.md` — product requirements and constraints.
  - `UNIVERSAL_PORTABILITY.md` — rationale for the C99 core and language wrappers.
  - `EXECUTIVE_SUMMARY.md` — high-level status and recommendations.
  - `QUICK_REFERENCE.md` — one-page developer guide; pair with `PALETTE_ENGINE_QUICKSTART.md`.
  - `API_ARCHITECTURE_DIAGRAM.md` — Mermaid API diagram.
- **Architecture & Standards**
  - `standards/ARCHITECTURE.md` — system design, data flow, and principles.
  - `standards/DOCUMENTATION.md` — terminology, DocC and Doxygen standards, review checklist.
  - `TOOLCHAIN_REPRODUCIBILITY.md`, `UNIVERSAL_PORTABILITY.md` — build determinism and portability notes.
- **How-to Guides**
  - `guides/DOCS_QUICKREF.md` — copy/paste snippets and commands.
  - `guides/SWIFT_DOCC_GUIDE.md`, `guides/SWIFT_DOCC_COMPLETE.md` — authoring DocC.
  - `guides/SWIFT_DOCC_PLUGIN_GUIDE.md` — publishing workflow.
  - `guides/UNIFIED_DOCS_BUILD.md` — Makefile-driven build system for C + Swift docs.
  - `SWIFT_DOCC_404_SOLUTION.md`, `publish-swift-package/` (distribution).
- **Implementation, Status, and Rationale**
  - `IMPLEMENTATION_STATUS.md`, `IMPLEMENTATION_CHECKLIST.md` — what exists and what is complete.
  - `USAGE_AND_FULFILLMENT_ANALYSIS.md`, `OUTPUT_PATTERNS.md` — how the API is used and where it meets the PRD.
  - `DOCUMENTATION_SUMMARY.md`, `ANALYSIS_INDEX.md`, `ALGORITHM_COMPARISON_ANALYSIS.md` — analysis, rationale, and algorithm parity notes.
  - `INCREMENTAL_SWATCH_SPECIFICATION.md`, `incremental-swatch-plan.md`, `PALETTE_ENGINE_QUICKSTART.md` — swatch/incremental palette plans.
- **Release, Branching, and Compliance**
  - `BRANCHING_STRATEGY.md`, `BRANCH_PROTECTION_GUIDE.md`, `BRANCH_STRATEGY_IMPLEMENTATION.md`.
  - `RELEASE_PLAYBOOK.md`, `RELEASE_GATES.md`, `RELEASE_TAGGING.md`, `RELEASE_TEMPLATE.md`, `RELEASE_TEST_REPORT.md`, `RC_WORKFLOW.md`.
  - `ARTIFACTS_SPECIFICATION.md`, `ARTIFACT_AUDIT_PROCEDURES.md`, `VERSION_MAPPING.md`, `BADGES.md`.
- **Stress, Parity, and Testing**
  - `stress-test/` — performance, stability, and coverage investigations.
  - `specs/003.5-c-algo-parity/` (see `specs` dir) — C/WASM parity runners; reports live in `specs/003.5-c-algo-parity/tools/parity-runner/src/report.c` and `DevDocs/ALGORITHM_COMPARISON_ANALYSIS.md`.
  - `SWATCH_DEMO_README.md`, `PALETTE_ENGINE_QUICKSTART.md` — demo and integration references.

## Maintenance Rules
- Add new documents to the map above and to `00_START_HERE.md` so navigation stays consistent.
- Update line counts and test references when the codebase shifts; avoid unverifiable claims.
- Keep rationale in place: link back to PRD and analysis docs whenever behavior or API changes.
- Prefer `guides/UNIFIED_DOCS_BUILD.md` for doc build instructions to avoid drift in command listings here.
