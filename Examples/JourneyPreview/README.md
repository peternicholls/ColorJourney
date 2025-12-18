# JourneyPreview - ColorJourney Demo App

A professional SwiftUI demo app showcasing ColorJourney's perceptually uniform color palette generation. This app serves as both a demonstration for developers and an interactive playground for exploring the color engine's capabilities.

## Overview

- **Date**: December 17, 2025  
- **Feature**: 005-demo-app-refresh

JourneyPreview focuses on:

- Exploring generated color journeys and palettes.
- Evaluating accessibility and contrast behavior across backgrounds.
- Exporting palettes as Swift and CSS code snippets for real-world use.

## Key Technical Decisions

### 1. Architecture Pattern: MVVM

**Decision**: Use Model-View-ViewModel (MVVM) pattern with SwiftUI.

**Rationale**:
- Standard pattern for SwiftUI applications.
- Clean separation of concerns between UI and business logic.
- SwiftUI's `@StateObject` and `@Published` work naturally with MVVM.
- Easier testing of business logic independent of the user interface.

**Alternatives Considered**:
- TCA (The Composable Architecture) — rejected as overkill for this demo app's complexity.
- MVC — rejected as a poor fit for SwiftUI's declarative nature.

### 2. Navigation: NavigationSplitView

**Decision**: Use `NavigationSplitView` for sidebar-based navigation.

**Rationale**:
- Native macOS look and feel.
- Built-in sidebar collapse behavior.
- Scales well for multiple views and future iOS support with adaptive layouts.

### 3. Color Display: Rounded Square Swatches

**Decision**: Display colors as rounded square tiles with configurable sizes.

**Rationale**:
- Matches modern UI patterns (e.g., Finder, Photos).
- Rounded corners feel more approachable and visually consistent.
- Size slider provides a familiar interaction for changing swatch size.
- Shadow and hover effects add depth without overwhelming the design.

### 4. Large Palette Handling

**Decision**: Three-tier approach with warning (50), advisory (100), and hard limit (200) for number of colors displayed.

**Rationale**:
- Performance is not the issue (C core handles millions of colors per second).
- **50 colors**: Can display comfortably in a grid without scrolling on most screens.
- **100 colors**: Requires paged/grouped display but remains performant.
- **200 colors**: UI practical limit; beyond this the interface becomes unusable.

**Implementation**:
- Grid mode: Standard display for ≤ 50 colors.
- Grouped mode: 20-color groups for 51–100 colors.
- Paged mode: 25-color pages for 101–200 colors.
- Refused: > 200 colors, with helpful messaging to the user.

### 5. Code Snippet Generation

**Decision**: Generate Swift and CSS snippets from the current palette parameters.

**Rationale**:
- Primary audience is developers.
- Swift is the native language for Apple platforms.
- CSS covers common web use cases.
- Copy-to-clipboard functionality reduces friction when using generated code.

**Formats Supported**:

| Format         | Use Case                           |
|----------------|------------------------------------|
| CSS Variables  | `--palette-color-0`, etc.         |
| CSS Classes    | `.color-0`, `.color-1`, etc.      |
| Swift Colors   | Static color array definitions    |
| Swift Usage    | How to create and apply a journey |

## Performance Considerations

### Palette Generation

UI overhead dominates actual generation time. The underlying C core generates colors in approximately **0.6 μs per color**:

- 50 colors: ~30 μs  
- 200 colors: ~120 μs

### SwiftUI Rendering

For a `LazyVGrid` with 200 items:

- Initial render: ~16 ms (about one frame).
- Resize/scroll: Handled efficiently by SwiftUI's native optimizations.
- Hover states: Only individual views update on interaction.

### Memory Usage

Each swatch stores:

- `ColorJourneyRGB`: 12 bytes (3 floats).
- `SwatchDisplay`: ~48 bytes (UUID, index, size enum, optional strings).

Total memory for 200 swatches is less than **10 KB**, so memory usage is negligible compared to typical app overhead.

## Accessibility Considerations

1. **VoiceOver Support**
   - Grid container has a meaningful accessibility label.
   - Selected state is announced clearly.
   - All swatches have accessibility labels including their hex values.

2. **Contrast Checking**
   - Text on swatches adapts to background luminance.
   - Low-contrast swatches display a warning badge.
   - Multiple background presets are available for testing.

3. **Keyboard Navigation**
   - Standard SwiftUI focus handling is used.
   - Tab navigation through interactive controls is fully supported.

## References

- [SwiftUI NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [WCAG 2.1 Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Human Interface Guidelines – Color](https://developer.apple.com/design/human-interface-guidelines/color)
## Features

### Palette Explorer
- **Interactive Controls**: Sliders, steppers, and pickers for palette size, delta spacing, and style
- **Live Preview**: Real-time swatch updates as you adjust parameters
- **Background Control**: Change display background with preset or custom colors
- **Swatch Sizing**: Adjust swatch size from small to extra-large (like Finder/Photos)
- **Rounded Swatches**: Professional rounded square tiles with hover effects
- **Copy Code**: Ready-to-use Swift and CSS code snippets with one-click copy

### Usage Examples
- **Swift Integration**: Code samples showing how to use ColorJourney in your projects
- **CSS Export**: CSS class definitions and custom properties for web use
- **Parameter Controls**: Adjust and see code update in real-time
- **Multi-language Support**: Switch between Swift and CSS output formats

### Large Palette Handling
- **Advisory Messaging**: Clear warnings for palettes above recommended thresholds
- **Safe Display Modes**: Grid, paged, or grouped display for large sets
- **Performance Info**: Real-time generation timing and performance notes
- **Request Limits**: Hard limit at 200 colors with helpful guidance

## Quick Start

### Running the App

```sh
# From repository root
cd Examples/JourneyPreview
swift run
```

### In Xcode

1. Open `Package.swift` in Xcode
2. Select the JourneyPreview scheme
3. Run (⌘R) or use Canvas preview (⌥⌘↩)

### Building

```sh
swift build
# or for release
swift build -c release
```

## Navigation

The app uses a sidebar navigation with four sections:

| View | Purpose |
|------|---------|
| **Palette Explorer** | Generate and customize palettes with full control |
| **Usage Examples** | Copy-ready code snippets for integration |
| **Large Palettes** | Safe handling of 50-200 color requests |
| **About** | Information about ColorJourney |

## Architecture

```
JourneyPreview/
├── ContentView.swift          # Main navigation
├── JourneyPreviewApp.swift    # App entry point
├── Models/                    # Data models
│   ├── ColorSetRequest.swift  # Palette request parameters
│   ├── SwatchDisplay.swift    # Swatch rendering data
│   ├── CodeSnippet.swift      # Code generation
│   ├── UserAdjustment.swift   # Input tracking
│   └── InputValidation.swift  # Validation utilities
├── Views/                     # SwiftUI views
│   ├── PaletteExplorerView.swift
│   ├── UsageExamplesView.swift
│   ├── LargePaletteView.swift
│   └── Shared/
│       ├── SwatchGrid.swift   # Reusable swatch grid
│       ├── AdvisoryBox.swift  # Warning/info boxes
│       └── CodeSnippetView.swift
├── ViewModels/                # View logic
│   ├── PaletteExplorerViewModel.swift
│   ├── UsageExamplesViewModel.swift
│   └── LargePaletteViewModel.swift
└── Tests/                     # Unit and snapshot tests
```

## Customization

### Add a Custom Journey Style

```swift
let config = ColorJourneyConfig(
    anchors: [myAnchorColor],
    lightness: .lighter,
    chroma: .vivid,
    contrast: .high,
    temperature: .warm
)
let journey = ColorJourney(config: config)
let palette = journey.discrete(count: 12)
```

### Available Preset Styles

| Style | Description |
|-------|-------------|
| `.balanced` | Neutral, versatile default |
| `.pastelDrift` | Light, muted, soft contrast |
| `.vividLoop` | Saturated, high-contrast, seamless loop |
| `.nightMode` | Dark, subdued colors |
| `.warmEarth` | Warm hues, natural character |
| `.coolSky` | Cool hues, light and airy |

## Performance

- **Generation**: ~0.6μs per color
- **UI Updates**: <100ms for all controls
- **Maximum Palette**: 200 colors (UI limit)
- **Recommended**: ≤50 colors for optimal display

## Requirements

- Swift 5.9+
- macOS 14+ or iOS 17+
- Xcode 15+ (for development)

## Related

- [ColorJourney Documentation](../../README.md)
- [Swift API Reference](../../Docs/swift-api.html)
- [C API Reference](../../Docs/api/index.html)
