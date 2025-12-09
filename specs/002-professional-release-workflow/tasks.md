---
description: "Task list for Professional Release Workflow feature implementation"
---

# Tasks: Professional Release Workflow

**Input**: Design documents from `/specs/002-professional-release-workflow/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Constitution mandates tests; release automation, packaging, badge updater, and reproducibility checks are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create release workflow documentation structure in specs/002-professional-release-workflow/
- [ ] T002 Define branch protection requirements (develop, main, release-candidate/*) and required checks to be enforced in GitHub settings
- [ ] T003 [P] Configure CI/CD base workflow in .github/workflows/core-ci.yml
- [ ] T004 [P] Add CHANGELOG.md and README.md templates to repository root

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [ ] T005 Rename main branch to develop and update all repository references (docs, workflows, badges)
- [ ] T006 [P] Apply GitHub branch protections for develop, main, and release-candidate/* (required checks, no direct pushes, block main→develop)
- [ ] T007 [P] Update CI workflows to target develop, release-candidate/*, and main with required status checks in .github/workflows/core-ci.yml
- [ ] T008 [P] Implement CMake build system for C library in Sources/CColorJourney/ with macOS/Linux/Windows targets
- [ ] T009 [P] Ensure Swift SPM configuration is source-only in Sources/ColorJourney/Package.swift (no binaries/xcframeworks)
- [ ] T010 [P] Configure packaging scripts for Swift and C in scripts/ with explicit include/exclude lists (Docs included; DevDocs, Docker/Makefiles, cross-language sources excluded) and artifact audit hooks
- [ ] T011 Add automated tests for release automation (RC create/delete, tagging, packaging, badge updater) and wire them into CI required checks
- [ ] T012 Document release playbook in DevDocs/RELEASE_PLAYBOOK.md
- [ ] T013 [P] Pin toolchains in CI (Swift 5.9, CMake ≥3.16, compiler versions) and record in DevDocs/RELEASE_PLAYBOOK.md
- [ ] T014 Add reproducibility check job: rerun packaging on the same RC tag, compare artifact hashes, fail on mismatch, and document the procedure in DevDocs/RELEASE_PLAYBOOK.md

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Establish Git Branching Strategy (Priority: P1) 🎯 MVP

**Goal**: Implement and document a branching strategy supporting continuous development and stable releases.

**Independent Test**: Git workflow is established and documented; develop branch exists with protection rules; main/release branches follow the specified pattern.

### Implementation for User Story 1

- [ ] T015 [US1] Update repository settings to reflect develop as primary and main as release-only (depends on T005/T006)
- [ ] T016 [P] [US1] Document branching strategy in DevDocs/BRANCHING_STRATEGY.md
- [ ] T017 [US1] Update CI/CD triggers for new branch names in .github/workflows/core-ci.yml
- [ ] T018 [US1] Add branch protection documentation to DevDocs/BRANCH_PROTECTION.md

**Checkpoint**: User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Implement Release Candidate Workflow (Priority: P1)

**Goal**: Enable creation, testing, and promotion of release candidate branches with CI gates.

**Independent Test**: RC workflow can be executed end-to-end; RC branches can be created, tested, and promoted or iterated.

### Implementation for User Story 2

- [ ] T019 [P] [US2] Implement RC branch creation script in scripts/create-rc-branch.sh
- [ ] T020 [P] [US2] Configure CI/CD to trigger full test + packaging matrix on release-candidate/* and block promotion/tagging if any artifact build fails
- [ ] T021 [US2] Add RC branch deletion automation in scripts/delete-rc-branch.sh
- [ ] T022 [US2] Add RC re-release support (rc.N increment script, changelog draft update, CI rerun) in scripts/
- [ ] T023 [US2] Document RC workflow and promotion gates in DevDocs/RC_WORKFLOW.md

**Checkpoint**: User Story 2 should be fully functional and testable independently

---

## Phase 5: User Story 3 - Semantic Versioning Release Tagging (Priority: P1)

**Goal**: Ensure releases follow SemVer 2.0.0 and are tagged correctly.

**Independent Test**: Release tags follow SemVer format; Git tags correctly mark release versions; CHANGELOG reflects version numbering.

### Implementation for User Story 3

- [ ] T024 [P] [US3] Implement SemVer tagging script in scripts/tag-release.sh
- [ ] T025 [P] [US3] Update CHANGELOG.md with release entries in repository root
- [ ] T026 [US3] Document tagging and changelog process in DevDocs/RELEASE_TAGGING.md

**Checkpoint**: User Story 3 should be fully functional and testable independently

---

## Phase 6: User Story 4 - Multi-Platform Release (Swift vs C) (Priority: P1)

**Goal**: Release Swift and C libraries separately with independent versioning and clean artifacts.

**Independent Test**: Both Swift SPM package and C library can be released independently; release artifacts are correctly packaged for each platform.

### Implementation for User Story 4

- [ ] T027 [P] [US4] Implement Swift SPM artifact packaging in scripts/package-swift.sh with enforced include/exclude lists (Docs included; no DevDocs/C sources/examples)
- [ ] T028 [P] [US4] Implement C static library packaging in scripts/package-c.sh with macOS/Linux/Windows matrix outputs and `.a`-only artifacts (no Swift/DevDocs)
- [ ] T029 [US4] Document artifact contents, allowed/forbidden paths, and packaging rules in DevDocs/ARTIFACTS.md
- [ ] T030 [US4] Add VersionMapping documentation to DevDocs/VERSION_MAPPING.md (Swift → required C core version)

**Checkpoint**: User Story 4 should be fully functional and testable independently

---

## Phase 7: User Story 5 - Future-Proof Multi-Language Architecture (Priority: P2)

**Goal**: Document and enable future language bindings with modular release infrastructure.

**Independent Test**: Architecture documented; build system supports modular language-specific releases; CI/CD can be extended for new platforms.

### Implementation for User Story 5

- [ ] T031 [P] [US5] Document future binding architecture in DevDocs/FUTURE_BINDINGS.md
- [ ] T032 [US5] Update CI/CD workflow templates for extensibility in .github/workflows/
- [ ] T033 [US5] Add guidance for new language integration in DevDocs/NEW_LANGUAGE_GUIDE.md

**Checkpoint**: User Story 5 should be fully functional and testable independently

---

## Phase 8: User Story 6 - Clean Release Artifacts (Priority: P2)

**Goal**: Ensure release packages contain only necessary files for each language/platform.

**Independent Test**: Release artifacts are audited; unnecessary files are excluded from language-specific releases.

### Implementation for User Story 6

- [ ] T034 [P] [US6] Audit Swift and C release artifact contents in scripts/audit-artifacts.sh (enforce include/exclude from FR-007/FR-008)
- [ ] T035 [US6] Update artifact packaging scripts to exclude unwanted files in scripts/
- [ ] T036 [US6] Document artifact audit process in DevDocs/ARTIFACT_AUDIT.md

**Checkpoint**: User Story 6 should be fully functional and testable independently

---

## Phase 9: User Story 7 - Essential Badges and Release Information (Priority: P2)

**Goal**: Display only essential badges on README and automate badge updates.

**Independent Test**: README includes only critical badges; deprecated or clutter badges are removed; badges are accurate and auto-update.

### Implementation for User Story 7

- [ ] T037 [P] [US7] Implement version badge automation in .github/workflows/badge-update.yml with freshness SLA (<5 minutes post-release)
- [ ] T038 [P] [US7] Implement build status badge in .github/workflows/core-ci.yml
- [ ] T039 [US7] Document badge requirements and update process in DevDocs/BADGES.md
- [ ] T040 [US7] Audit README.md for badge clutter and remove non-essential badges in repository root

**Checkpoint**: User Story 7 should be fully functional and testable independently

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T041 [P] Documentation updates in Docs/
- [ ] T042 Code cleanup and refactoring across scripts/ and DevDocs/
- [ ] T043 Performance optimization for CI/CD workflows in .github/workflows/
- [ ] T044 [P] Additional artifact validation in scripts/
- [ ] T045 Security hardening for release automation in .github/workflows/
- [ ] T046 Run quickstart.md validation in specs/002-professional-release-workflow/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies
- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 4 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 6 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 7 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Within Each User Story
- Models before services/scripts
- Scripts before documentation
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities
- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tasks for a user story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

- T015 [US1] Update repository settings to reflect develop/main roles
- T016 [P] [US1] Document branching strategy in DevDocs/BRANCHING_STRATEGY.md

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery
1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy
With multiple developers:
1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes
- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
