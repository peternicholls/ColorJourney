# Implementation Plan: JourneyPreview Demo Refresh

**Branch**: `005-demo-app-refresh` | **Date**: December 17, 2025 | **Spec**: [specs/005-demo-app-refresh/spec.md](specs/005-demo-app-refresh/spec.md)
**Input**: Feature specification from `/specs/005-demo-app-refresh/spec.md`

## Summary

Update the JourneyPreview demo app to become a featured, professional-grade showcase for the ColorJourney engine. The app will be split into clear, navigable views for palette exploration, code/CSS usage examples, and large palette handling. All controls will be interactive, with advisory copy, technical info, and code snippets (with copy buttons). The UI will be responsive, accessible, and visually polished, with robust handling for large palette requests.

## Technical Context

**Language/Version**: Swift 5.9 (SwiftUI), C99 (core engine)
**Primary Dependencies**: SwiftUI, ColorJourney C core, ColorJourney Swift wrapper
**Storage**: N/A (in-memory only)
**Testing**: XCTest (Swift), manual UI/UX validation, snapshot tests for swatch rendering
**Target Platform**: macOS (primary), iOS (secondary, if feasible)
**Project Type**: App (demo, developer-facing)
**Performance Goals**: Palette generation ≤1ms for 100 colors; UI updates <100ms for all controls; no visible freezes for up to 200 swatches
**Constraints**: No external dependencies beyond ColorJourney; must use C core for all color logic; must remain deterministic and portable
**Scale/Scope**: 3–4 main views/pages, up to 200 swatches per palette, single-user (demo only)

## Constitution Check

- C core is canonical: All color logic must use the C core (no Swift-only color math)
- Perceptual integrity: All color math in OKLab, enforced by C core
- Designer-centric controls: UI exposes only high-level intent (palette size, delta, background, etc.)
- Deterministic output: Same input = same palette, always
- Comprehensive testing: All new UI and wrapper logic must have tests; visual output must be snapshot-tested

## Project Structure

### Documentation (this feature)

```text
specs/005-demo-app-refresh/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Examples/JourneyPreview/
├── ContentView.swift
├── Views/
│   ├── PaletteExplorerView.swift
│   ├── UsageExamplesView.swift
│   ├── LargePaletteView.swift
│   └── Shared/
│       ├── SwatchGrid.swift
│       ├── AdvisoryBox.swift
│       └── CodeSnippetView.swift
├── ViewModels/
│   ├── PaletteExplorerViewModel.swift
│   ├── UsageExamplesViewModel.swift
│   └── LargePaletteViewModel.swift
├── Resources/
│   └── ...
└── Tests/
    ├── Snapshot/
    └── UITests/
```

**Structure Decision**: The feature will be implemented as a SwiftUI app in Examples/JourneyPreview, with modular views and view models for each major page, shared UI components, and snapshot/UI tests. All color logic will be routed through the C core via the Swift wrapper.

## Complexity Tracking

_No constitution violations expected. All requirements are in line with project principles and standards._
