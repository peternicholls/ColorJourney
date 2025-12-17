# API Contract: SwatchDisplay Model

**Version**: 1.0  
**Module**: Models/SwatchDisplay.swift

## Overview

Value type representing a single color swatch for display in the UI.

## Public Interface

```swift
struct SwatchDisplay: Identifiable, Equatable
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | UUID | Unique identifier for SwiftUI lists |
| `index` | Int | Position in palette (0-based) |
| `color` | ColorJourneyRGB | The color value |
| `size` | SwatchSizePreference | Display size preference |
| `label` | String? | Optional label (usually index + 1) |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `hexString` | String | "#RRGGBB" format |
| `rgbString` | String | "rgb(R, G, B)" format |
| `relativeLuminance` | Double | Luminance for WCAG calculations |
| `textColor` | Color | Contrasting text color (black/white) |

### Static Methods

| Method | Parameters | Returns |
|--------|------------|---------|
| `fromPalette(_:size:showLabels:)` | ([ColorJourneyRGB], SwatchSizePreference, Bool) | [SwatchDisplay] |

## Behavior Contracts

1. **hexString Format**: Always uppercase, always 6 characters, always prefixed with "#"

2. **textColor Logic**:
   - If `relativeLuminance > 0.179`: return `.black`
   - Otherwise: return `.white`

3. **fromPalette Indexing**: Swatches are indexed starting at 0, labels show index + 1

## Test Requirements

```swift
// TC-SD-001: Hex string format
func testHexStringFormat() {
    let swatch = SwatchDisplay(
        id: UUID(),
        index: 0,
        color: ColorJourneyRGB(red: 1.0, green: 0.5, blue: 0.0),
        size: .medium
    )
    XCTAssertTrue(swatch.hexString.hasPrefix("#"))
    XCTAssertEqual(swatch.hexString.count, 7)
}

// TC-SD-002: Text color contrast
func testTextColorContrast() {
    let lightSwatch = SwatchDisplay(
        id: UUID(), index: 0,
        color: ColorJourneyRGB(red: 1.0, green: 1.0, blue: 1.0),
        size: .medium
    )
    // Light background should have dark text
    XCTAssertEqual(lightSwatch.textColor, .black)
    
    let darkSwatch = SwatchDisplay(
        id: UUID(), index: 0,
        color: ColorJourneyRGB(red: 0.0, green: 0.0, blue: 0.0),
        size: .medium
    )
    // Dark background should have light text
    XCTAssertEqual(darkSwatch.textColor, .white)
}

// TC-SD-003: Palette conversion
func testFromPalette() {
    let colors = [
        ColorJourneyRGB(red: 1, green: 0, blue: 0),
        ColorJourneyRGB(red: 0, green: 1, blue: 0),
        ColorJourneyRGB(red: 0, green: 0, blue: 1)
    ]
    let swatches = SwatchDisplay.fromPalette(colors, size: .large, showLabels: true)
    
    XCTAssertEqual(swatches.count, 3)
    XCTAssertEqual(swatches[0].index, 0)
    XCTAssertEqual(swatches[2].index, 2)
}
```

## Luminance Calculation

```swift
// WCAG relative luminance formula
relativeLuminance = 0.2126 * R + 0.7152 * G + 0.0722 * B

// Where R, G, B are linearized:
// if sRGB <= 0.04045: linear = sRGB / 12.92
// else: linear = ((sRGB + 0.055) / 1.055) ^ 2.4
```
