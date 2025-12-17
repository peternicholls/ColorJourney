# Research: JourneyPreview Demo App Refresh

**Feature**: 005-demo-app-refresh  
**Date**: December 17, 2025

## Overview

This document captures research and technical decisions made during the design phase of the JourneyPreview demo app refresh.

## Key Technical Decisions

### 1. Architecture Pattern: MVVM

**Decision**: Use Model-View-ViewModel (MVVM) pattern with SwiftUI.

**Rationale**:
- Clean separation of concerns
- SwiftUI's `@StateObject` and `@Published` work naturally with MVVM
- Easier testing of business logic independent of UI
- Standard pattern for SwiftUI applications

**Alternatives Considered**:
- MVC (rejected: poor fit for SwiftUI's declarative nature)
- TCA (rejected: overkill for demo app complexity)

### 2. Navigation: NavigationSplitView

**Decision**: Use `NavigationSplitView` for sidebar-based navigation.

**Rationale**:
- Native macOS look and feel
- Scales well for multiple views
- Built-in sidebar collapse behavior
- Future iOS support with adaptive layouts

### 3. Color Display: Rounded Square Swatches

**Decision**: Display colors as rounded square tiles with configurable sizes.

**Rationale**:
- Matches modern UI patterns (Finder, Photos app)
- Rounded corners feel more approachable
- Size slider provides familiar interaction
- Shadow effects add depth without overwhelming

### 4. Large Palette Handling

**Decision**: Three-tier approach with warning (50), advisory (100), and hard limit (200).

**Rationale**:
- 50 colors: Can display comfortably in grid without scrolling on most screens
- 100 colors: Requires paged/grouped display but still performant
- 200 colors: UI practical limit; beyond this becomes unusable
- Performance is not the issue (C core handles millions per second)

**Implementation**:
- Grid mode: Standard display for ≤50 colors
- Grouped mode: 20-color groups for 51-100 colors
- Paged mode: 25-color pages for 101-200 colors
- Refused: >200 colors with helpful messaging

### 5. Code Snippet Generation

**Decision**: Generate Swift and CSS snippets from current palette parameters.

**Rationale**:
- Primary audience is developers
- Swift is native language for Apple platforms
- CSS covers web use cases
- Copy-to-clipboard reduces friction

**Formats Supported**:
| Format | Use Case |
|--------|----------|
| Swift Usage | How to create a journey |
| Swift Colors | Static color array |
| CSS Classes | .color-0, .color-1, etc. |
| CSS Variables | --palette-color-0, etc. |

## Performance Considerations

### Palette Generation

The C core generates colors in ~0.6μs per color:
- 50 colors: ~30μs
- 200 colors: ~120μs

UI overhead dominates actual generation time.

### SwiftUI Rendering

LazyVGrid with 200 items:
- Initial render: ~16ms (one frame)
- Resize/scroll: Native optimization handles well
- Hover states: Individual view updates only

### Memory Usage

Each swatch stores:
- ColorJourneyRGB: 12 bytes (3 floats)
- SwatchDisplay: ~48 bytes (UUID, index, size enum, optional strings)
- Total for 200 swatches: <10KB

## Accessibility Considerations

1. **VoiceOver Support**:
   - All swatches have accessibility labels with hex values
   - Selected state is announced
   - Grid container has meaningful label

2. **Contrast Checking**:
   - Low-contrast swatches show warning badge
   - Text on swatches adapts to background luminance
   - Multiple background presets for testing

3. **Keyboard Navigation**:
   - Tab navigation through controls
   - Standard SwiftUI focus handling

## References

- [Human Interface Guidelines - Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [WCAG 2.1 Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [SwiftUI NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
