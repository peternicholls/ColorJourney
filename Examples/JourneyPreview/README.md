# JourneyPreview - ColorJourney Demo App




























































































































- [SwiftUI NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)- [WCAG 2.1 Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)- [Human Interface Guidelines - Color](https://developer.apple.com/design/human-interface-guidelines/color)## References   - Standard SwiftUI focus handling   - Tab navigation through controls3. **Keyboard Navigation**:   - Multiple background presets for testing   - Text on swatches adapts to background luminance   - Low-contrast swatches show warning badge2. **Contrast Checking**:   - Grid container has meaningful label   - Selected state is announced   - All swatches have accessibility labels with hex values1. **VoiceOver Support**:## Accessibility Considerations- Total for 200 swatches: <10KB- SwatchDisplay: ~48 bytes (UUID, index, size enum, optional strings)- ColorJourneyRGB: 12 bytes (3 floats)Each swatch stores:### Memory Usage- Hover states: Individual view updates only- Resize/scroll: Native optimization handles well- Initial render: ~16ms (one frame)LazyVGrid with 200 items:### SwiftUI RenderingUI overhead dominates actual generation time.- 200 colors: ~120μs- 50 colors: ~30μsThe C core generates colors in ~0.6μs per color:### Palette Generation## Performance Considerations| CSS Variables | --palette-color-0, etc. || CSS Classes | .color-0, .color-1, etc. || Swift Colors | Static color array || Swift Usage | How to create a journey ||--------|----------|| Format | Use Case |**Formats Supported**:- Copy-to-clipboard reduces friction- CSS covers web use cases- Swift is native language for Apple platforms- Primary audience is developers**Rationale**:**Decision**: Generate Swift and CSS snippets from current palette parameters.### 5. Code Snippet Generation- Refused: >200 colors with helpful messaging- Paged mode: 25-color pages for 101-200 colors- Grouped mode: 20-color groups for 51-100 colors- Grid mode: Standard display for ≤50 colors**Implementation**:- Performance is not the issue (C core handles millions per second)- 200 colors: UI practical limit; beyond this becomes unusable- 100 colors: Requires paged/grouped display but still performant- 50 colors: Can display comfortably in grid without scrolling on most screens**Rationale**:**Decision**: Three-tier approach with warning (50), advisory (100), and hard limit (200).### 4. Large Palette Handling- Shadow effects add depth without overwhelming- Size slider provides familiar interaction- Rounded corners feel more approachable- Matches modern UI patterns (Finder, Photos app)**Rationale**:**Decision**: Display colors as rounded square tiles with configurable sizes.### 3. Color Display: Rounded Square Swatches- Future iOS support with adaptive layouts- Built-in sidebar collapse behavior- Scales well for multiple views- Native macOS look and feel**Rationale**:**Decision**: Use `NavigationSplitView` for sidebar-based navigation.### 2. Navigation: NavigationSplitView- TCA (rejected: overkill for demo app complexity)- MVC (rejected: poor fit for SwiftUI's declarative nature)**Alternatives Considered**:- Standard pattern for SwiftUI applications- Easier testing of business logic independent of UI- SwiftUI's `@StateObject` and `@Published` work naturally with MVVM- Clean separation of concerns**Rationale**:**Decision**: Use Model-View-ViewModel (MVVM) pattern with SwiftUI.### 1. Architecture Pattern: MVVM## Key Technical DecisionsThis document captures research and technical decisions made during the design phase of the JourneyPreview demo app refresh.## Overview**Date**: December 17, 2025**Feature**: 005-demo-app-refresh  A professional SwiftUI demo app showcasing ColorJourney's perceptually uniform color palette generation. This app serves as both a demonstration for developers and an interactive playground for exploring the color engine's capabilities.

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
