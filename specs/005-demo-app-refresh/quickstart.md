# Quickstart: JourneyPreview Demo App

**Feature**: 005-demo-app-refresh  
**Date**: December 17, 2025

## Overview

This quickstart guide covers common integration scenarios for the JourneyPreview demo app.

## Scenario 1: Generate a Basic Palette

**Goal**: Generate 8 colors with balanced style.

```swift
import ColorJourney

let journey = ColorJourney(
    config: .singleAnchor(
        ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
        style: .balanced
    )
)

let palette = journey.discrete(count: 8)

// Use in SwiftUI
ForEach(palette.indices, id: \.self) { i in
    Rectangle().fill(palette[i].color)
}
```

## Scenario 2: Large Palette with Paging

**Goal**: Generate 100+ colors with safe display.

```swift
import ColorJourney

let journey = ColorJourney(
    config: .singleAnchor(baseColor, style: .vividLoop)
)

// Generate all colors
let allColors = journey.discrete(count: 150)

// Page through them (25 per page)
let pageSize = 25
let currentPage = 0

let pageColors = Array(allColors.dropFirst(currentPage * pageSize).prefix(pageSize))
```

## Scenario 3: Export to CSS

**Goal**: Generate CSS custom properties for web use.

```swift
let palette = journey.discrete(count: 12)

var css = ":root {\n"
for (index, color) in palette.enumerated() {
    let hex = String(format: "#%02X%02X%02X", 
                     Int(color.red * 255),
                     Int(color.green * 255),
                     Int(color.blue * 255))
    css += "  --palette-color-\(index): \(hex);\n"
}
css += "}"

print(css)
```

Output:
```css
:root {
  --palette-color-0: #8033CC;
  --palette-color-1: #9040DD;
  --palette-color-2: #A050EE;
  /* ... */
}
```

## Scenario 4: Custom Style Configuration

**Goal**: Create a warm, muted palette for a design system.

```swift
let config = ColorJourneyConfig(
    anchors: [brandColor],
    lightness: .lighter,
    chroma: .muted,
    contrast: .medium,
    temperature: .warm
)

let journey = ColorJourney(config: config)
let palette = journey.discrete(count: 16)
```

## Scenario 5: Validate User Input

**Goal**: Safely handle user input for palette size.

```swift
import JourneyPreview

// Validate palette count
let result = InputValidation.validatePaletteCount(userInput)

switch result {
case .valid(let count):
    generatePalette(count: count)
    
case .advisory(let message, let count):
    showInfo(message)
    generatePalette(count: count)
    
case .warning(let message, let count):
    showWarning(message)
    if userConfirms {
        generatePalette(count: count)
    }
    
case .invalid(let error, let suggestion):
    showError(error, suggestion: suggestion)
}
```

## Scenario 6: Copy Code to Clipboard

**Goal**: Copy generated code snippet to clipboard.

```swift
import AppKit

func copyToClipboard(_ code: String) -> Bool {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    return pasteboard.setString(code, forType: .string)
}

// Usage
let snippet = CodeGenerator.generateSwiftUsage(request: currentRequest)
if copyToClipboard(snippet) {
    showConfirmation("Copied!")
}
```

## Scenario 7: Accessibility Contrast Check

**Goal**: Check if a swatch has sufficient contrast.

```swift
func checkContrast(_ swatch: SwatchDisplay, against background: Double) -> WCAGLevel {
    let swatchLuminance = swatch.relativeLuminance
    
    let lighter = max(swatchLuminance, background)
    let darker = min(swatchLuminance, background)
    let ratio = (lighter + 0.05) / (darker + 0.05)
    
    return WCAGLevel(contrastRatio: ratio)
}

// Usage
let wcagLevel = checkContrast(swatch, against: 0.15)
switch wcagLevel {
case .aaa: print("Excellent contrast")
case .aa: print("Good contrast")
case .aaLarge: print("OK for large text")
case .fail: print("Poor contrast - consider different background")
}
```

## Common Patterns

### Creating SwatchDisplay from Palette

```swift
let colors = journey.discrete(count: 20)
let swatches = SwatchDisplay.fromPalette(
    colors,
    size: .medium,
    showLabels: true
)
```

### Building a ColorSetRequest

```swift
let request = ColorSetRequest(
    count: 12,
    deltaTarget: .medium,
    backgroundColor: ColorJourneyRGB(red: 0.1, green: 0.1, blue: 0.1),
    swatchSize: .large,
    style: .balanced,
    anchorColor: myAnchorColor
)
```

### Handling Large Requests

```swift
if request.count > RequestLimits.warningThreshold {
    if request.count > RequestLimits.absoluteMaximum {
        // Refuse - too large
        showError("Maximum is \(RequestLimits.absoluteMaximum) colors")
    } else if request.count > RequestLimits.recommendedMaximum {
        // Show warning, use paged display
        displayMode = .paged
    } else {
        // Show advisory, use grouped display
        displayMode = .grouped
    }
}
```

## API Quick Reference

| Operation | Method |
|-----------|--------|
| Create journey | `ColorJourney(config: .singleAnchor(...))` |
| Generate palette | `journey.discrete(count: n)` |
| Single color | `journey.discrete(at: index)` |
| Range of colors | `journey.discrete(range: 0..<50)` |
| Sample continuous | `journey.sample(at: 0.5)` |
| Convert to SwiftUI | `color.color` |
| Convert to hex | `SwatchDisplay.hexString` |
