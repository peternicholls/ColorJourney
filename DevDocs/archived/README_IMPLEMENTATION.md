# ColorJourney

A high-performance, perceptually-aware colour journey system for iOS, macOS, and other Apple platforms. Built with a modular C core for portability and performance, wrapped in an idiomatic Swift API.

## Overview

ColorJourney generates designer-quality, perceptually-aware colour sequences based on OKLab colour space. It handles all the complex perceptual math in optimized C code while providing a clean, Swift-first interface.

**Core Philosophy:**
- **Perceptual Foundation**: All calculations use OKLab, a perceptually uniform colour space
- **Design-First**: Generate intentional, curated palettes—not mechanical gradients
- **High-Level Controls**: Configure via perceptual biases ("weights & biases"), not raw RGB
- **Deterministic by Default**: Same input always produces same output
- **Optional Variation**: Add organic micro-variations while maintaining predictability

## Features

### Color Journey Types

**Single-Anchor Journeys**
- Start from one colour and traverse a full wheel or partial arc
- Non-linear hue pacing with shaped chroma and lightness curves
- Designed to feel curated, not algorithmic

**Multi-Anchor Journeys**
- Interpolate smoothly between 2–5 anchor colours
- Open sequences, closed loops, or ping-pong modes
- Avoid muddy midpoints with intelligent dynamics

### Perceptual Dynamics

Control the feel of your palette with high-level perceptual biases:

- **Lightness**: Neutral, Lighter, Darker, or Custom
- **Chroma**: Neutral, Muted, Vivid, or Custom (saturation control)
- **Contrast**: Enforce minimum OKLab ΔE between colours
- **Mid-Journey Vibrancy**: Enhance colours at transition points
- **Temperature**: Warm, Cool, or Neutral bias
- **Loop Mode**: Open (linear), Closed (circular), or Ping-Pong

### Generation Modes

- **Continuous**: Sample the journey at any t ∈ [0,1]
- **Discrete**: Generate N perceptually distinct colours with contrast enforcement
- **Large Palettes**: Scales from 3 to 300+ colours with coherent reuse patterns

### Optional Variation Layer

Add subtle, deterministic micro-variations to palettes:

- **Enabled/Disabled**: Toggle on/off independently
- **Dimensions**: Vary hue, lightness, chroma, or combinations
- **Strength**: Subtle, Noticeable, or Custom magnitude
- **Deterministic Seeds**: Same seed = same variation across sessions

### SwiftUI Integration

- Automatic conversion to SwiftUI `Color`
- Linear and custom gradient generation
- Seamless integration with `@State` and `@Binding`

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/peternicholls/ColorJourney.git", branch: "main")
```

Or in Xcode: **File → Add Packages** → paste the URL.

## Quick Start

### Basic Single-Anchor Journey

```swift
import ColorJourney

let blueColor = ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8)
let journey = ColorJourney(
    config: .singleAnchor(blueColor, style: .balanced)
)

// Sample at any point
let color = journey.sample(at: 0.5)  // Returns ColorJourneyRGB

// Generate discrete palette
let palette = journey.discrete(count: 10)  // [ColorJourneyRGB]
```

### Multi-Anchor Journey

```swift
let anchors = [
    ColorJourneyRGB(r: 1.0, g: 0.3, b: 0.3),  // Red
    ColorJourneyRGB(r: 0.3, g: 1.0, b: 0.3),  // Green
    ColorJourneyRGB(r: 0.3, g: 0.3, b: 1.0)   // Blue
]

var config = ColorJourneyConfig.multiAnchor(anchors, style: .balanced)
config.loopMode = .closed  // Connect end to start

let journey = ColorJourney(config: config)
let palette = journey.discrete(count: 20)
```

### Customize Dynamics

```swift
var config = ColorJourneyConfig(anchors: [baseColor])
config.lightness = .lighter
config.chroma = .vivid
config.contrast = .high
config.temperature = .warm
config.midJourneyVibrancy = 0.6

let journey = ColorJourney(config: config)
```

### Add Variation

```swift
var config = ColorJourneyConfig(anchors: [baseColor])
config.variation = .subtle(
    dimensions: [.hue, .lightness],
    seed: 42  // Optional: use for deterministic variation
)

let journey = ColorJourney(config: config)
```

### SwiftUI Integration

```swift
import SwiftUI

let journey = ColorJourney(config: .singleAnchor(color))

struct ContentView: View {
    var body: some View {
        VStack {
            // Use as gradient
            Rectangle()
                .fill(journey.linearGradient(stops: 20))
            
            // Use discrete palette
            HStack {
                ForEach(journey.discrete(count: 5), id: \.hashValue) { color in
                    Color(journeyRGB: color)
                }
            }
        }
    }
}
```

## Available Styles

Pre-configured style presets:

- **`.balanced`** – Neutral across all dimensions
- **`.pastelDrift`** – Light, muted, soft contrast
- **`.vividLoop`** – Saturated, distinct, closed loop
- **`.nightMode`** – Darker, slightly muted
- **`.warmEarth`** – Warm temperature bias, slightly darker
- **`.coolSky`** – Cool temperature bias, lighter

## Architecture

### C Core (`CColorJourney`)

High-performance, portable C library:
- OKLab colour space conversions (fast cubic root approximations)
- Journey interpolation with designed waypoints
- Discrete palette generation with contrast enforcement
- Deterministic variation generation (xoshiro128+)
- Optimized for `-O3 -ffast-math` in release builds

### Swift Wrapper (`ColorJourney`)

Idiomatic Swift interface:
- Value-type configuration (`ColorJourneyConfig`)
- Enum-based controls for discoverability
- Automatic C↔Swift bridging
- SwiftUI extensions
- Thread-safe (immutable after creation)

## Perceptual Guarantees

- **Readability**: Colors avoid extreme dark/light combinations
- **Contrast**: Minimum OKLab ΔE enforced between adjacent colours
- **Smoothness**: OKLab interpolation prevents sudden perceptual jumps
- **Consistency**: Deterministic output by default; randomness opt-in

## Performance

Designed for high-performance use:

- C implementation with fast approximations
- ~0.1ms to generate 100 discrete colours
- ~0.6μs per sample (continuous mode)
- Small memory footprint (~2KB per journey)

Tested on:
- **macOS 10.15+**
- **iOS 13+**
- **watchOS 6+**
- **visionOS 1+**
- **tvOS 13+**
- **Catalyst 13+**

## Testing

Comprehensive test suite with 49 tests covering:

- Color type operations
- Single and multi-anchor journeys
- All perceptual dynamics
- All loop modes
- Variation layer (determinism, dimensions, strength)
- Discrete palette generation
- Edge cases (extremes, empty palettes)
- SwiftUI integration
- Performance benchmarks

Run tests:

```bash
swift test
```

## File Structure

```
ColorJourney/
├── Package.swift                    # SPM manifest
├── README.md                        # This file
├── Sources/
│   ├── CColorJourney/
│   │   ├── ColorJourney.c         # Core C implementation
│   │   └── include/
│   │       └── ColorJourney.h     # Public C API
│   └── ColorJourney/
│       └── ColorJourney.swift     # Swift wrapper & extensions
├── Tests/
│   └── ColorJourneyTests/
│       └── ColorJourneyTests.swift # Comprehensive test suite
├── Examples/
│   ├── Example.swift               # Original example
│   └── ExampleUsage.swift          # Detailed usage examples
└── DevDocs/
    └── PRD.md                      # Product requirements & philosophy
```

## Design Principles

From the PRD:

1. **Produce intentional, curated palettes** — avoid mechanical gradients
2. **Perceptually uniform foundation** — OKLab for stable, predictable behaviour
3. **High-level controls** — configure via feel, not numbers
4. **Deterministic by default** — same input → same output always
5. **Optional structured variation** — add organic feel without breaking predictability
6. **Designer-friendly** — feel like a tool built for design, not algorithms

## Contributing

Contributions welcome! Areas of interest:

- Additional style presets
- SwiftUI view helpers (colour swatches, sliders, etc.)
- Performance optimizations
- Extended platform support
- Documentation and examples

## License

See [LICENSE](LICENSE) file.

## References

- **OKLab** – Björn Ottosson's perceptually uniform colour space
- **Color Science** – Fast approximations and gamma-correct interpolation
- **Design Patterns** – Value-oriented Swift, protocol composition

---

Built with ❤️ for designers and developers who care about colour.
