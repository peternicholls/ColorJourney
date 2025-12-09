# Implementation Plan: Professional Release Workflow

**Branch**: `002-professional-release-workflow` | **Date**: 2025-12-09 | **Spec**: [specs/002-professional-release-workflow/spec.md](specs/002-professional-release-workflow/spec.md)
**Input**: Feature specification from `/specs/002-professional-release-workflow/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a professional release workflow that renames `main` to `develop`, introduces RC branching (`release-candidate/X.Y.Z-rc.N`) with CI gates, applies SemVer tagging on `main`, and delivers clean, language-specific release artifacts (Swift SPM source-only, C static `.a`) with minimal docs plus user-facing `/Docs`. Swift and C releases version independently with explicit C core dependency mapping; README badges are limited to essential release/build/platform indicators.

## Technical Context

**Language/Version**: Swift 5.9 (swift-tools-version), C99 core; Git tooling  
**Primary Dependencies**: SwiftPM, CMake 3.16+, Git/GitHub Actions  
**Storage**: N/A  
**Testing**: XCTest for Swift, Makefile-driven C harness (`make test-c`), optional future CTest  
**Target Platform**: macOS, Linux, Windows for C; Apple platforms + SPM for Swift; future WASM/JS/Python bindings  
**Project Type**: Multi-language library (C core + Swift wrapper; future bindings)  
**Performance Goals**: RC workflow end-to-end <30 minutes; CI parity with current test durations  
**Constraints**: Release artifacts must exclude DevDocs and non-essential files; C releases static `.a` only; deterministic, reproducible builds  
**Scale/Scope**: Single repo with multiple language outputs; initial scope Swift + C, extensible to additional bindings

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Universal Portability: C99 core remains canonical; release workflow must keep C core as source of truth for bindings.
- Deterministic Output: RC and release builds must be reproducible; no nondeterministic packaging.
- Comprehensive Testing: CI gates must cover C core and Swift wrapper; no release without tests.
- Designer-Centric Configuration & Perceptual Integrity: Release changes cannot alter API semantics or OKLab fidelity; documentation must preserve user intent framing.
- Governance: SemVer tagging and changelog updates must align with constitution and amendment rules.

Post-Phase-1 status: No constitution violations identified; release workflow tasks remain subject to deterministic build and testing gates.

## Project Structure

### Documentation (this feature)

```text
specs/002-professional-release-workflow/
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output (/speckit.plan)
├── data-model.md        # Phase 1 output (/speckit.plan)
├── quickstart.md        # Phase 1 output (/speckit.plan)
├── contracts/           # Phase 1 output (/speckit.plan)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Sources/
├── CColorJourney/       # Canonical C99 core + headers
└── ColorJourney/        # Swift wrapper and configuration

Tests/
├── CColorJourneyTests/  # C core tests
└── ColorJourneyTests/   # Swift tests

DevDocs/                 # Developer-facing docs (excluded from artifacts)
Docs/                    # End-user docs to include in releases
.github/workflows/       # CI/CD (to be extended for RC/release automation)
```

**Structure Decision**: Single multi-language library repository with C core + Swift wrapper; release workflow operates at repo root with language-specific packaging paths above.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _None identified_ | N/A | N/A |
