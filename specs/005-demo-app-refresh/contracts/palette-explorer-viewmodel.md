# API Contract: PaletteExplorerViewModel

**Version**: 1.0  
**Module**: Views/PaletteExplorerViewModel.swift

## Overview

ViewModel for the Palette Explorer view, managing state for color generation controls and swatch display.

## Public Interface

```swift
@MainActor
class PaletteExplorerViewModel: ObservableObject
```

### Published Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `swatches` | [SwatchDisplay] | [] | Generated color swatches |
| `paletteCount` | Int | 8 | Number of colors to generate |
| `selectedStyle` | JourneyStyle | .balanced | Color journey style |
| `deltaTarget` | DeltaTarget | .medium | Perceptual spacing |
| `anchorColor` | ColorJourneyRGB | (0.5, 0.2, 0.8) | Base color |
| `swatchSize` | SwatchSizePreference | .medium | Display size |
| `backgroundColor` | ColorJourneyRGB | (0.1, 0.1, 0.1) | Grid background |
| `generationTimeMs` | Double | 0.0 | Last generation time |
| `showCountWarning` | Bool | false | Show large count warning |
| `showContrastWarnings` | Bool | true | Show accessibility warnings |

### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `generatePalette()` | none | void | Regenerate swatches from current settings |
| `resetToDefaults()` | none | void | Reset all settings to initial values |
| `validateAndSetCount(_:)` | String | void | Validate and set palette count |

### Behavior Contracts

1. **Automatic Regeneration**: Changing any control property triggers `generatePalette()` automatically via Combine.

2. **Warning Thresholds**:
   - `paletteCount > 50`: Set `showCountWarning = true`
   - `paletteCount > 200`: Clamp to 200, show error

3. **Generation Timing**: `generationTimeMs` updated on every palette generation.

## Test Requirements

```swift
// TC-PEV-001: Initial state
func testInitialState() {
    let vm = PaletteExplorerViewModel()
    XCTAssertEqual(vm.paletteCount, 8)
    XCTAssertEqual(vm.selectedStyle, .balanced)
    XCTAssertTrue(vm.swatches.isEmpty || vm.swatches.count == 8)
}

// TC-PEV-002: Palette generation
func testPaletteGeneration() {
    let vm = PaletteExplorerViewModel()
    vm.paletteCount = 12
    vm.generatePalette()
    XCTAssertEqual(vm.swatches.count, 12)
}

// TC-PEV-003: Large count warning
func testLargeCountWarning() {
    let vm = PaletteExplorerViewModel()
    vm.validateAndSetCount("60")
    XCTAssertTrue(vm.showCountWarning)
}

// TC-PEV-004: Reset to defaults
func testResetToDefaults() {
    let vm = PaletteExplorerViewModel()
    vm.paletteCount = 50
    vm.resetToDefaults()
    XCTAssertEqual(vm.paletteCount, 8)
}
```

## Error Handling

| Error Condition | Handling |
|-----------------|----------|
| Invalid count input | Clamp to valid range [1-200] |
| Invalid anchor color | Use default anchor |
| Empty palette result | Show error advisory |
