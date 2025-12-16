# ColorJourney Preview App

A simple SwiftUI app demonstrating ColorJourney's color palette generation with discrete swatches.

## Features

- **Multiple Journey Styles**: Demonstrates different journey configurations (warm to cool, monochrome, etc.)
- **Discrete Swatches**: Shows individually generated colors from each journey
- **Live Preview**: Can be previewed directly in Xcode with `#Preview`
- **Dark Theme**: Modern dark UI matching the reference designs

## Running

### In Xcode Preview

1. Open the project in Xcode
2. Open `ContentView.swift`
3. Enable Canvas (⌥⌘↩)
4. The preview will show automatically

### As Standalone App

```sh
# From Examples/JourneyPreview directory
swift run
```

### Building

```sh
swift build
```

## Journey Examples

The app demonstrates three different journey styles:

1. **Sunset to Ocean**: Warm orange transitioning through purple to blue (vivid loop style)
2. **Cool Breeze**: Cool cyan to green gradient (balanced style)
3. **Warm Glow**: Warm monochrome coral tones (pastel style)

## Customization

Edit `ContentView.swift` to add your own journeys:

```swift
("My Journey", generateJourney(
    anchor: ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.8),
    style: .balanced,
    count: 10
))
```

Available styles: `.balanced`, `.pastelDrift`, `.vividLoop`, `.nightMode`, `.warmEarth`, `.coolSky`

## Requirements

- Swift 5.9+
- macOS 14+ or iOS 17+
- Xcode 15+ (for preview)
