# Implementation Plan: CocoaPods Release

**Branch**: `003-cocoapods-release` | **Date**: 2025-12-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-cocoapods-release/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enable CocoaPods distribution for ColorJourney as a complementary package manager alongside Swift Package Manager. The implementation will create a validated podspec that includes both Swift wrapper and C core, integrate CocoaPods publishing into the existing release workflow, and maintain version parity with SPM releases. This extends the existing professional release workflow (002) to support broader iOS/macOS ecosystem compatibility without replacing or disrupting SPM as the primary distribution method.

## Technical Context

**Language/Version**: Ruby 2.6+ (CocoaPods), Swift 5.9 (existing wrapper), C99 (existing core)  
**Primary Dependencies**: CocoaPods 1.10.0+, Swift Package Manager (existing), Git  
**Storage**: N/A (package metadata and distribution only)  
**Testing**: XCTest (existing Swift tests), C core tests (existing), pod spec lint, pod lib lint  
**Target Platform**: iOS 13.0+, macOS 10.15+ (matching existing Swift wrapper requirements)  
**Project Type**: Mobile library (existing structure; adding CocoaPods packaging layer)  
**Performance Goals**: Pod validation <5 minutes, pod installation comparable to SPM (within 20%)  
**Constraints**: Must maintain version parity with SPM, zero breaking changes to existing build system, CocoaPods Trunk publication must be automatable in CI/CD  
**Scale/Scope**: Single podspec file, integration into existing release workflow, documentation updates only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Universal Portability First ✅ PASS
- **Requirement**: C99 core remains canonical; language wrappers are convenience layers
- **Assessment**: CocoaPods is a distribution mechanism, not a new implementation layer. The existing C core and Swift wrapper remain unchanged. CocoaPods simply provides an alternative installation method for the same codebase.
- **Compliance**: No violations. The C core remains the source of truth, and no platform-specific behavior is introduced.

### II. Perceptual Integrity via OKLab ✅ PASS
- **Requirement**: All color math in OKLab; deterministic output
- **Assessment**: This feature adds no color math or algorithms—only packaging and distribution.
- **Compliance**: No violations. No changes to color processing logic.

### III. Designer-Centric Configuration ✅ PASS
- **Requirement**: High-level aesthetic controls, not low-level parameters
- **Assessment**: This feature does not modify the API or configuration layer.
- **Compliance**: No violations. API remains unchanged.

### IV. Deterministic Output with Optional Variation ✅ PASS
- **Requirement**: Deterministic by default; seeded variation optional
- **Assessment**: Distribution method does not affect algorithmic behavior.
- **Compliance**: No violations. Output determinism is preserved.

### V. Comprehensive Testing & Quality Assurance ✅ PASS
- **Requirement**: Every feature must have unit tests; cross-platform validation
- **Assessment**: CocoaPods integration will be tested via `pod spec lint`, `pod lib lint`, and integration tests in a test iOS project. Existing test suite remains unchanged.
- **Compliance**: Validation tests added for podspec; existing tests unaffected.

### API Stability ✅ PASS
- **Requirement**: Semantic versioning; no breaking changes to C API
- **Assessment**: CocoaPods releases will use identical version numbers to SPM releases, maintaining semantic versioning consistency.
- **Compliance**: No API changes introduced; version parity enforced.

### Performance Requirements ⚠️ MONITORED
- **Requirement**: Maintain continuous sampling ≤1μs, discrete palette ≤1ms for 100 colors
- **Assessment**: CocoaPods installation may have different build characteristics, but runtime performance is determined by the underlying C core and Swift wrapper, which remain unchanged.
- **Compliance**: Pod installation time must be within 20% of SPM (NFR-003). Runtime performance unaffected by distribution method.

**Overall Assessment**: ✅ ALL GATES PASS - No constitutional violations. This feature is purely additive (distribution layer) and does not modify core implementation, API design, or algorithmic behavior.

**Post-Design Recheck (Phase 1)**: No new violations introduced by podspec design, CI gating, or documentation updates. Performance and determinism remain governed by the unchanged C core and Swift wrapper.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
ColorJourney.podspec     # New: CocoaPods specification file
README.md                # Modified: Add CocoaPods installation instructions
.github/workflows/       # Modified: Extend release workflow for CocoaPods
├── release.yml          # Add pod spec lint and pod trunk push steps
└── ...

Sources/                 # Existing: No changes to source code
├── CColorJourney/       # C core (included in podspec)
│   ├── include/
│   │   └── ColorJourney.h
│   └── ColorJourney.c
└── ColorJourney/        # Swift wrapper (included in podspec)
    ├── ColorJourney.swift
    ├── Configuration.swift
    └── ...

Tests/                   # Existing: No changes to test suite
├── CColorJourneyTests/
└── ColorJourneyTests/

scripts/                 # Modified: Add CocoaPods publishing script
└── publish-cocoapods.sh # New: Script for manual CocoaPods publishing

DevDocs/                 # Modified: Update release playbook
└── RELEASE_PLAYBOOK.md  # Add CocoaPods publishing procedures
```

**Structure Decision**: This is a mobile library with existing single-project structure. CocoaPods integration adds a packaging layer without modifying the source code organization. The podspec references existing `Sources/CColorJourney/` and `Sources/ColorJourney/` directories. CI/CD workflows are extended to include CocoaPods validation and publishing steps.

## Complexity Tracking

No constitutional violations detected. This section is not applicable for this feature.
