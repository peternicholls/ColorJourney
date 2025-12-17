# Data Model: JourneyPreview Demo App

**Feature**: 005-demo-app-refresh  
**Date**: December 17, 2025

## Overview

This document defines the data models used in the JourneyPreview demo application.

## Entity Relationship Diagram

```
┌─────────────────────┐         ┌─────────────────────┐
│   ColorSetRequest   │─────────│    SwatchDisplay    │
│                     │ 1    N  │                     │
├─────────────────────┤         ├─────────────────────┤
│ count: Int          │         │ id: UUID            │
│ deltaTarget         │         │ index: Int          │
│ backgroundColor     │         │ color: RGB          │
│ swatchSize          │         │ size: SizePreference│
│ styleName: String   │         │ label: String?      │
│ anchorColor: RGB    │         │ contrastNote?       │
│ bypassLargeWarning  │         └─────────────────────┘
└─────────────────────┘                   │
         │                                │
         │ generates                      │ displays
         ▼                                ▼
┌─────────────────────┐         ┌─────────────────────┐
│    CodeSnippet      │         │   AdvisoryInfo      │
├─────────────────────┤         ├─────────────────────┤
│ id: UUID            │         │ type: AdvisoryType  │
│ type: SnippetType   │         │ title: String       │
│ code: String        │         │ message: String     │
│ copyState: CopyState│         │ technicalDetails?   │
└─────────────────────┘         └─────────────────────┘
```

## Core Entities

### ColorSetRequest

Represents user input for palette generation.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `count` | Int | Number of colors | 1-200 |
| `deltaTarget` | DeltaTarget | Perceptual spacing | tight/medium/wide |
| `backgroundColor` | ColorJourneyRGB | Display background | RGB [0,1] |
| `swatchSize` | SwatchSizePreference | Tile size | small/medium/large/extraLarge |
| `styleName` | String | Journey style name | Preset names |
| `anchorColor` | ColorJourneyRGB | Base color | RGB [0,1] |
| `bypassLargeWarning` | Bool | Skip >50 warning | true/false |

### SwatchDisplay

Represents a rendered color swatch.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `index` | Int | Position in palette |
| `color` | ColorJourneyRGB | The actual color |
| `size` | SwatchSizePreference | Display size |
| `label` | String? | Optional label (index) |
| `contrastNote` | AccessibilityContrastNote? | WCAG info |

**Computed Properties**:
- `hexString`: "#RRGGBB" format
- `rgbString`: "rgb(R, G, B)" format
- `relativeLuminance`: For contrast calculations
- `prefersDarkText`: Text color recommendation

### CodeSnippet

Represents a copyable code sample.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `type` | SnippetType | Language/format type |
| `code` | String | The actual code |
| `copyState` | CopyState | UI copy state |

**SnippetType Values**:
- `swiftUsage`: Full journey creation code
- `swiftColors`: Color array definition
- `css`: CSS class definitions
- `cssVariables`: CSS custom properties

### UserAdjustment

Tracks user input changes for undo/context.

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | Date | When adjustment occurred |
| `controlType` | ControlType | Which control changed |
| `previousValue` | AdjustmentValue | Old value |
| `newValue` | AdjustmentValue | New value |

## Supporting Types

### DeltaTarget

```swift
enum DeltaTarget {
    case tight   // ΔE ~0.02
    case medium  // ΔE ~0.035
    case wide    // ΔE ~0.05
}
```

### SwatchSizePreference

```swift
enum SwatchSizePreference {
    case small      // 44pt, 8pt radius
    case medium     // 80pt, 12pt radius
    case large      // 110pt, 16pt radius
    case extraLarge // 150pt, 20pt radius
}
```

### RequestLimits

```swift
enum RequestLimits {
    static let warningThreshold = 50
    static let recommendedMaximum = 100
    static let absoluteMaximum = 200
}
```

### CopyState

```swift
enum CopyState {
    case idle
    case copying
    case success
    case failed(String)
}
```

### AdvisoryType

```swift
enum AdvisoryType {
    case info
    case warning
    case error
    case success
    case performance
}
```

## Validation Rules

| Entity | Rule | Error |
|--------|------|-------|
| ColorSetRequest | count ≥ 1 | countTooLow |
| ColorSetRequest | count ≤ 200 | countExceedsMaximum |
| InputValidation | hex 6 chars | Invalid hex format |
| InputValidation | RGB 0-255 | Component out of range |

## State Management

The app uses SwiftUI's native state management:

- `@StateObject`: View models owned by views
- `@Published`: Observable properties in view models
- `@State`: Local view state (hover, selection)
- `@Binding`: Two-way communication (controls)

## Data Flow

```
User Input → ViewModel.@Published → ColorSetRequest
     │
     ▼
ColorJourney.discrete(count:) → [ColorJourneyRGB]
     │
     ▼
SwatchDisplay.fromPalette() → [SwatchDisplay]
     │
     ▼
SwatchGrid → UI Render
```
