# Analysis & Rationale Index

Use this index to locate the documents that explain *why* the system is shaped the way it is and how it is validated. For navigation and high-level onboarding, see `README.md` and `00_START_HERE.md` in this folder.

## Core Reference Stack
- `PRD.md` — canonical requirements and constraints for the palette engine.
- `UNIVERSAL_PORTABILITY.md` — rationale for the C99 core + language wrappers strategy.
- `IMPLEMENTATION_STATUS.md` — what exists today, with architecture notes.
- `IMPLEMENTATION_CHECKLIST.md` — feature/status checklist tied back to the PRD.
- `EXECUTIVE_SUMMARY.md` — stakeholder-facing status and recommendations.

## Usage and API Reasoning
- `QUICK_REFERENCE.md` — how to use the API (continuous vs. discrete) with examples.
- `PALETTE_ENGINE_QUICKSTART.md` and `OUTPUT_PATTERNS.md` — practical scenarios and example flows.
- `API_ARCHITECTURE_DIAGRAM.md` — Mermaid class diagram of the Swift surface.
- `USAGE_AND_FULFILLMENT_ANALYSIS.md` — where the current API meets the PRD and where to extend.

## Algorithm and Parity Investigations
- `ALGORITHM_COMPARISON_ANALYSIS.md` — differences between the C core and the WASM implementation (cube root precision, chroma modulation, hue discretization, contrast handling).
- `stress-test/` — deep dives on performance, numerical stability, edge cases, portability, and extensibility.
- `specs/005-c-algo-parity/` (see `specs` directory) — parity runner code and reports used to validate behavior across implementations.

## Release, Branching, and Compliance
- `BRANCHING_STRATEGY.md`, `BRANCH_PROTECTION_GUIDE.md`, `BRANCH_STRATEGY_IMPLEMENTATION.md` — how we manage code flow.
- `RELEASE_PLAYBOOK.md`, `RELEASE_GATES.md`, `RELEASE_TAGGING.md`, `RELEASE_TEMPLATE.md`, `RELEASE_TEST_REPORT.md`, `RC_WORKFLOW.md` — release gates, tagging, and RC workflow with checklists.
- `ARTIFACTS_SPECIFICATION.md`, `ARTIFACT_AUDIT_PROCEDURES.md`, `VERSION_MAPPING.md`, `BADGES.md` — artifacts, auditability, and version mapping.

## Current Facts to Anchor the Analysis
- Core engine: `Sources/CColorJourney/ColorJourney.c` (~867 LOC, C99).
- Swift surface: `Sources/ColorJourney/` (~885 LOC across configuration, mapper, journey class, SwiftUI extensions, umbrella doc).
- Tests: `Tests/ColorJourneyTests/ColorJourneyTests.swift` (52 XCTest cases) and `Tests/CColorJourneyTests/test_c_core.c` (C harness). Parity runners live under `Tests/Parity/`.

## How to Use This Index
- Need rationale for a change? Start with `PRD.md` and `UNIVERSAL_PORTABILITY.md`, then open the relevant analysis file above.
- Need evidence for behavior? Pair the analysis doc with the corresponding tests in `Tests/` or parity reports in `specs/005-c-algo-parity/`.
- Adding new investigative docs? Link them in the relevant section here and in `README.md` to keep navigation consistent.
