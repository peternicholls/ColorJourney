# Tasks: JourneyPreview Demo Refresh

**Feature**: JourneyPreview Demo Refresh (005-demo-app-refresh)

---

## Phase 1: Setup

- [X] T001 Create modular directory structure for new views and view models in Examples/JourneyPreview/Views and Examples/JourneyPreview/ViewModels
- [X] T002 [P] Add placeholder files for PaletteExplorerView, UsageExamplesView, LargePaletteView, and their view models
- [X] T003 [P] Add Shared/ components: SwatchGrid.swift, AdvisoryBox.swift, CodeSnippetView.swift
- [X] T004 Add snapshot and UI test folders in Examples/JourneyPreview/Tests

---

## Phase 2: Foundational

- [X] T005 Implement ColorSetRequest, SwatchDisplay, CodeSnippet, and UserAdjustment models in Examples/JourneyPreview/ViewModels/
- [X] T006 [P] Integrate ColorJourney C core and Swift wrapper into demo app target (linking, bridging)
- [X] T007 [P] Set up basic navigation between views/pages in ContentView.swift
- [X] T008 [P] Implement input validation utilities for palette size, delta, and background

---

## Phase 3: User Story 1 (P1) - Explore incremental palettes

- [X] T009 [US1] Implement PaletteExplorerView UI: sliders, steppers, background picker, and swatch size control in Examples/JourneyPreview/Views/PaletteExplorerView.swift
- [X] T010 [P] [US1] Implement PaletteExplorerViewModel logic: palette generation, delta enforcement, and state management
- [X] T011 [P] [US1] Implement SwatchGrid.swift: rounded square swatch grid, size and background adaptation
- [X] T012 [P] [US1] Implement AdvisoryBox.swift: dynamic advisory copy and technical info
- [X] T013 [P] [US1] Implement CodeSnippetView.swift: code sample display and copy button with confirmation
- [X] T014 [US1] Wire up all controls and state to live-update swatches and code
- [X] T015 [US1] Add snapshot tests for PaletteExplorerView and SwatchGrid

---

## Phase 4: User Story 2 (P2) - Compare usage examples

- [X] T016 [US2] Implement UsageExamplesView UI: code/CSS sample display, parameter controls in Examples/JourneyPreview/Views/UsageExamplesView.swift
- [X] T017 [P] [US2] Implement UsageExamplesViewModel: code/CSS generation logic, state management
- [X] T018 [P] [US2] Extend CodeSnippetView.swift for CSS and language switching, copy confirmation
- [X] T019 [US2] Wire up controls to update code/CSS samples live
- [X] T020 [US2] Add snapshot tests for UsageExamplesView and CodeSnippetView

---

## Phase 5: User Story 3 (P3) - Handle large palette requests

- [X] T021 [US3] Implement LargePaletteView UI: warning/advisory messaging, safe display (paging/grouping) in Examples/JourneyPreview/Views/LargePaletteView.swift
- [X] T022 [P] [US3] Implement LargePaletteViewModel: threshold logic, performance notes, safe rendering
- [X] T023 [P] [US3] Integrate advisory and fallback logic for large requests in all relevant views
- [X] T024 [US3] Add snapshot/UI tests for large palette handling and edge cases

---

## Final Phase: Polish & Cross-Cutting

- [X] T025 Add accessibility/contrast checks to SwatchGrid and all color displays
- [X] T026 [P] Add error handling and inline validation for all user inputs
- [X] T027 [P] Add UI polish: animations, transitions, and professional visual details
- [X] T028 [P] Add documentation and inline comments for all new components
- [X] T029 [P] Update README and developer docs to reflect new demo app features
- [X] T030 [P] Implement refusal flow for requests >200 colors: UI messaging + tests in Examples/JourneyPreview/Views/LargePaletteView.swift and Tests/
- [X] T031 [P] Add responsiveness feedback (progress/loading indicators) and instrumentation to ensure <100ms UI updates in Examples/JourneyPreview/Views and ViewModels
- [X] T032 [P] Add unit/integration tests for view models, validation utilities, and C-core bridging to ensure deterministic palettes and performance targets in Examples/JourneyPreview/Tests
- [X] T033 [P] Add success-criteria validation harness: timing (SC-001), copy success (SC-002), responsiveness (SC-003), UX checklist (SC-004/SC-005) in Examples/JourneyPreview/Tests
- [X] T034 [P] Create Phase 0/1 docs: research.md, data-model.md, quickstart.md, and contracts/ outline in specs/005-demo-app-refresh/

---

## Dependencies

- Phase 1 and 2 must be completed before any user story phases
- User Story 1 (P1) is independent and can be developed/tested in parallel with foundational tasks
- User Story 2 (P2) and User Story 3 (P3) depend on foundational and some shared components
- Polish phase can proceed once all user stories are implemented

## Parallel Execution Examples

- T002, T003, T006, T007, T008 can be done in parallel after T001
- T010, T011, T012, T013 can be done in parallel after T009
- T017, T018 can be done in parallel after T016
- T022, T023 can be done in parallel after T021
- T026, T027, T028, T029 can be done in parallel after T025

## MVP Scope

- Complete all tasks in Phase 1, Phase 2, and Phase 3 (User Story 1)

## Format Validation

- All tasks follow strict checklist format: `- [ ] T### [P] [US#] Description with file path`
- Each user story phase is independently testable
- Parallelizable tasks are marked [P]
- File paths are explicit for each task
