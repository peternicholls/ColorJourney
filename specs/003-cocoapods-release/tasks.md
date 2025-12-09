# Tasks: CocoaPods Release

**Input**: plan.md, spec.md, research.md, data-model.md, contracts/
**Prerequisites**: Ruby+CocoaPods available; SPM workflow from feature 002 remains unchanged
**Alignment**: Following HexColor/Xcode-native pattern for minimal, maintainable Package.swift and clean distribution

## Phase 0: Verify Xcode Native Structure (Reference)
**Purpose**: Confirm ColorJourney follows Xcode-native pattern from HexColor guide
- [X] T000 [Reference] Verify Package.swift is at repository root and name matches repo name (ColorJourney)
- [X] T000b [Reference] Confirm Sources/ColorJourney/ and Sources/CColorJourney/ follow standard layout from File > New > Package
- [X] T000c [Reference] Validate all public APIs are marked public (C headers via include/, Swift extensions marked public)

## Phase 1: Setup (Shared Infrastructure)
**Purpose**: Initialize packaging artifacts and docs needed by all stories
- [X] T001 Create initial podspec scaffold with name/version/metadata in ColorJourney.podspec (version from Package.swift, no 'v' prefix)
- [X] T002 Create publish helper script with lint/push entrypoints in scripts/publish-cocoapods.sh
- [X] T003 Add CocoaPods section outline to DevDocs/RELEASE_PLAYBOOK.md describing roles and tokens

## Phase 2: Foundational (Blocking Prerequisites)
**Purpose**: Core assets required before user stories begin
- [X] T004 [P] Add CocoaPods demo fixture Podfile using local path under Examples/CocoaPodsDemo/Podfile
- [X] T005 Document trunk token/CLI prerequisites for CI in DevDocs/RC_WORKFLOW.md

## Phase 3: User Story 1 - iOS/macOS Developers Can Install via CocoaPods (Priority: P1) 🎯 MVP
**Goal**: Pod installs cleanly on iOS/macOS and APIs are accessible
**Independent Test**: From Examples/CocoaPodsDemo, `pod install` succeeds and a sample Swift file imports ColorJourney and builds a palette; user can write `import ColorJourney` and access all public APIs via autocomplete
- [X] T006 [US1] Populate podspec with source_files, public_header_files, swift_version, ios/macos targets in ColorJourney.podspec
- [X] T007 [P] [US1] Add usage sample that imports ColorJourney and calls a palette generation API in Examples/CocoaPodsDemo/Usage.swift (reference HexColor example pattern)
- [X] T008 [US1] Add Podfile snippet for local path install and pod install steps to specs/003-cocoapods-release/quickstart.md

## Phase 4: User Story 2 - Maintain Version Parity with SPM (Priority: P1)
**Goal**: CocoaPods versions always match SPM releases and git tags (semantic versioning without 'v' prefix)
**Independent Test**: A release tag `X.Y.Z` (no 'v') matches ColorJourney.podspec version and Package.swift version; parity check fails the release if mismatch
- [X] T009 [US2] Add parity check in scripts/publish-cocoapods.sh to compare podspec version against Package.swift and current git tag (verify no 'v' prefix in podspec)
- [X] T010 [US2] Note parity gate and required CHANGELOG entry in DevDocs/RELEASE_PLAYBOOK.md

## Phase 5: User Story 3 - Podspec Validates Successfully (Priority: P1)
**Goal**: `pod spec lint` passes with zero errors/warnings (following HexColor validation pattern)
**Independent Test**: `pod spec lint ColorJourney.podspec --verbose` succeeds for iOS 13.0+ and macOS 10.15+ using included Sources/ structure
- [X] T011 [US3] Add pod spec lint job to .github/workflows/release.yml gating releases before publication
- [X] T012 [P] [US3] Ensure podspec metadata (summary, description, homepage, license, authors) and license path are complete in ColorJourney.podspec; validate public_header_files paths match Sources/CColorJourney/include/

## Phase 6: User Story 4 - CocoaPods Release Automation (Priority: P1)
**Goal**: Release workflow automatically validates and publishes to CocoaPods Trunk (no 'v' prefix in version tag)
**Independent Test**: On tag `X.Y.Z` (semantic version, no 'v'), CI runs lint then `pod trunk push ColorJourney.podspec` with COCOAPODS_TRUNK_TOKEN; failure blocks release; pod appears on CocoaPods.org within 10 minutes
- [X] T013 [US4] Extend .github/workflows/release.yml to run `pod spec lint ColorJourney.podspec --verbose` then `pod trunk push ColorJourney.podspec` after lint succeeds, using COCOAPODS_TRUNK_TOKEN secret
- [X] T014 [P] [US4] Enhance scripts/publish-cocoapods.sh with trunk push command, dry-run flag, and retry/backoff using CI secret; verify version matches Package.swift
- [X] T015 [US4] Add failure-handling and manual fallback steps for CocoaPods to DevDocs/RELEASE_PLAYBOOK.md (reference HexColor manual push approach)

## Phase 7: User Story 5 - Documentation Shows Both Installation Methods (Priority: P2)
**Goal**: README clearly presents SPM and CocoaPods installation side by side (following HexColor documentation pattern)
**Independent Test**: README top section shows both methods with copy-pasteable snippets and version pinning guidance; user can find CocoaPods instructions without scrolling excessively
- [X] T016 [US5] Add CocoaPods installation section with Podfile snippet and platform targets to README.md (platform syntax: iOS 13.0+, macOS 10.15+)
- [X] T017 [P] [US5] Add version pinning example (`pod 'ColorJourney', '~> 1.2'`) and CHANGELOG link for CocoaPods users to README.md

## Final Phase: Polish & Cross-Cutting
**Purpose**: Validate end-to-end and record outcomes
- [X] T018 [P] Run quickstart steps (lint + trunk push dry-run + demo pod install) and capture results in DevDocs/RELEASE_TEST_REPORT.md
- [X] T019 Update DevDocs/IMPLEMENTATION_STATUS.md with completion notes for feature 003 and any follow-ups

## Dependencies & Execution Order
- Phase 0 (Reference) → Phase 1 → Phase 2 → all User Stories → Polish
- US1 depends on Foundational; US2 depends on US1 (version data); US3 depends on US1 (podspec) and US2 (version parity); US4 depends on US3; US5 can start after Foundational but should follow US1 for accurate instructions

## Parallel Execution Examples
- US1: T006 (podspec) then in parallel T007 usage sample and T008 docs
- US2: T009 parity script can run while T010 playbook note
- US3: T012 metadata edits can proceed while T011 CI job added
- US4: T014 script enhancements can run while T013 workflow wiring waits on lint job path
- US5: T017 pinning note can run alongside T016 main instructions
- Polish: T018 validation can run in parallel with T019 status doc update

## Implementation Strategy
- MVP = Complete through US1 (Phase 3) to enable CocoaPods installs; then layer parity (US2), lint gate (US3), automation (US4), docs polish (US5)
- Always run quickstart after US3/US4 changes to ensure lint/push remain green
