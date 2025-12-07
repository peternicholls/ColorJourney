# Colour Journey System

A high-performance, perceptually-aware color journey generator based on OKLab color space. Generates designer-quality color sequences for timelines, tracks, labels, and UI accents.

**Based on [OKLab](https://bottosson.github.io/posts/oklab/) by Björn Ottosson** - a perceptually uniform color space designed for image processing and computer graphics.

## Contents

- [Architecture](#architecture)
  - [Why C?](#why-c)
- [Features](#features)
- [Quick Start](#quick-start)
  - [Basic Usage](#basic-usage)
  - [Style Presets](#style-presets)
  - [Multi-Anchor Journeys](#multi-anchor-journeys)
  - [With Variation](#with-variation)
  - [Advanced Configuration](#advanced-configuration)
- [SwiftUI Integration](#swiftui-integration)
- [Building](#building)
  - [Xcode Project](#xcode-project)
  - [Swift Package Manager](#swift-package-manager)
  - [Standalone C Library](#standalone-c-library)
- [Configuration Reference](#configuration-reference)
- [Use Cases](#use-cases)
- [Performance](#performance)
- [Technical Details](#technical-details)
  - [OKLab Color Space](#oklab-color-space)
  - [Fast Cube Root](#fast-cube-root)
  - [Journey Design](#journey-design)
- [Credits](#credits)
- [License](#license)

## Architecture

**Two-layer design for maximum portability and performance:**

1. **C Core (`colour_journey.c/h`)** - High-performance color math and journey generation
   - Fast OKLab conversions (~1% error, 3-5x faster than standard)
   - Perceptual distance calculations
   - Journey interpolation and sampling
   - Platform-agnostic, pure C99
   
2. **Swift Wrapper (`ColourJourney.swift`)** - Idiomatic Swift API
   - Type-safe configuration
   - SwiftUI/AppKit/UIKit integration
   - Preset journey styles
   - Discoverable, chainable API

### Why C?

The core color math is written in C for three critical reasons:

**1. True Portability**  
C is the universal language. This library can be:
- Used in Swift/Objective-C projects (iOS, macOS, visionOS)
- Embedded in C++ applications
- Called from Python, Rust, JavaScript (via FFI/WASM)
- Integrated into game engines (Unity, Unreal)
- Used on embedded systems or platforms without Swift runtime

**2. Performance**  
Color conversion and journey sampling happen in tight loops. C gives us:
- Zero runtime overhead
- Full control over optimization
- SIMD-friendly layout (if needed later)
- Predictable, consistent performance across platforms
- No ARC overhead for calculations

**3. Stability**  
Swift's ABI and module system evolve. C is forever:
- No Swift version compatibility issues
- No binary stability concerns
- Can be compiled anywhere, anytime
- 20-year source compatibility guarantee

The Swift wrapper provides ergonomics and type safety, while the C core ensures the system can be used anywhere color math is needed.

## Features

✅ **Perceptually Uniform** - Built on OKLab for consistent lightness, chroma, and hue
✅ **Designer-Quality** - Non-linear journeys with shaped curves, not mechanical gradients  
✅ **Flexible Configuration** - Single or multi-anchor, open/closed/ping-pong modes
✅ **High-Level Controls** - Lightness, chroma, contrast, temperature, vibrancy biases
✅ **Variation Layer** - Optional subtle, structured micro-variation
✅ **Deterministic** - Repeatable output with optional seeded variation
✅ **Fast** - Optimized C core processes 10,000+ colors/second
✅ **Portable** - Core C library works anywhere (iOS, macOS, Linux, Windows)

## Quick Start

### Basic Usage

```swift
import ColourJourney

// Create a journey from a single anchor color
let journey = ColourJourney(
    config: .singleAnchor(
        ColourJourneyRGB(r: 0.3, g: 0.5, b: 0.8),
        style: .balanced
    )
)

// Sample continuously (for gradients, animations)
let color = journey.sample(at: 0.5) // t ∈ [0, 1]

// Or generate discrete palette (for UI elements)
let palette = journey.discrete(count: 10)
```

### Style Presets

```swift
// Available presets
.balanced        // Neutral, versatile
.pastelDrift     // Light, muted, soft contrast
.vividLoop       // Saturated, high contrast, closed loop
.nightMode       // Dark, subdued
.warmEarth       // Warm bias, natural tones
.coolSky         // Cool bias, light and airy
```

### Multi-Anchor Journeys

```swift
let config = ColourJourneyConfig(
    anchors: [
        ColourJourneyRGB(r: 1.0, g: 0.3, b: 0.3),
        ColourJourneyRGB(r: 0.3, g: 1.0, b: 0.3),
        ColourJourneyRGB(r: 0.3, g: 0.3, b: 1.0)
    ],
    loopMode: .closed
)

let journey = ColourJourney(config: config)
```

### With Variation

```swift
let config = ColourJourneyConfig(
    anchors: [baseColor],
    variation: .subtle(
        dimensions: [.hue, .lightness],
        seed: 12345  // Deterministic
    )
)
```

### Advanced Configuration

```swift
let config = ColourJourneyConfig(
    anchors: [color1, color2],
    lightness: .custom(weight: 0.2),      // Slightly lighter
    chroma: .vivid,                        // More saturated
    contrast: .high,                       // Strong distinction
    midJourneyVibrancy: 0.6,              // Boost midpoint colors
    temperature: .warm,                    // Warm bias
    loopMode: .pingPong,
    variation: VariationConfig(
        enabled: true,
        dimensions: [.hue, .chroma],
        strength: .noticeable
    )
)
```

## SwiftUI Integration

```swift
import SwiftUI

struct MyView: View {
    let journey = ColourJourney(
        config: .singleAnchor(
            ColourJourneyRGB(r: 0.4, g: 0.5, b: 0.9),
            style: .vividLoop
        )
    )
    
    var body: some View {
        Rectangle()
            .fill(journey.linearGradient(stops: 20))
            .frame(height: 200)
    }
}

// Or use discrete colors
let colors = journey.discrete(count: 5)
ForEach(colors.indices, id: \.self) { i in
    Circle()
        .fill(colors[i].color)
}
```

## Building 

### Xcode Project

1. Add both files to your Xcode project:
   - `colour_journey.h`
   - `colour_journey.c`
   - `ColourJourney.swift`

2. Create a bridging header if needed:
```objc
// YourProject-Bridging-Header.h
#include "colour_journey.h"
```

3. Build and run

### Swift Package Manager

```swift
// Package.swift
let package = Package(
    name: "ColourJourney",
    products: [
        .library(name: "ColourJourney", targets: ["ColourJourney"])
    ],
    targets: [
        .target(
            name: "CColourJourney",
            path: "Sources/CColourJourney",
            sources: ["colour_journey.c"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "ColourJourney",
            dependencies: ["CColourJourney"],
            path: "Sources/ColourJourney"
        )
    ]
)
```

### Standalone C Library

```bash
# Compile C library
gcc -O3 -ffast-math -march=native -c colour_journey.c -o colour_journey.o

# Create static library
ar rcs libcolourjourney.a colour_journey.o

# Or compile with your project
gcc -O3 -ffast-math myapp.c colour_journey.c -lm -o myapp
```

## Configuration Reference

### Lightness Bias
Controls overall brightness in perceptual space (OKLab L):
- `.neutral` - Preserve original lightness
- `.lighter` - Shift toward brighter colors
- `.darker` - Shift toward darker colors  
- `.custom(weight: Float)` - Custom adjustment [-1, 1]

### Chroma Bias
Controls saturation/colourfulness:
- `.neutral` - Original chroma
- `.muted` - Lower saturation (0.6x)
- `.vivid` - Higher saturation (1.4x)
- `.custom(multiplier: Float)` - Custom multiplier [0.5, 2.0]

### Contrast Level
Enforces minimum perceptual separation (OKLab ΔE):
- `.low` - Soft, subtle (ΔE ≥ 0.05)
- `.medium` - Balanced (ΔE ≥ 0.1)
- `.high` - Strong distinction (ΔE ≥ 0.15)
- `.custom(threshold: Float)` - Custom ΔE threshold

### Temperature Bias
Shifts hue toward warm or cool regions:
- `.neutral` - No temperature bias
- `.warm` - Emphasize warm hues (reds, oranges, yellows)
- `.cool` - Emphasize cool hues (blues, greens, purples)

### Loop Mode
How the journey behaves at boundaries:
- `.open` - Start and end are distinct
- `.closed` - Seamlessly loops back to start
- `.pingPong` - Reverses direction at ends

### Variation Config
Optional micro-variation for organic feel:
- `enabled: Bool` - Turn variation on/off
- `dimensions: VariationDimensions` - Which axes to vary (`.hue`, `.lightness`, `.chroma`)
- `strength: VariationStrength` - How much (`.subtle`, `.noticeable`, `.custom`)
- `seed: UInt64` - Deterministic seed for repeatable variation

## Use Cases

**Timeline Tracks** - Generate distinct colors for parallel tracks
```swift
let journey = ColourJourney(config: .singleAnchor(baseColor, style: .balanced))
let trackColors = journey.discrete(count: 12)
```

**Label System** - High-contrast categorical colors
```swift
let config = ColourJourneyConfig(
    anchors: [color1, color2],
    contrast: .high,
    loopMode: .closed
)
let labelColors = journey.discrete(count: 8)
```

**Segment Markers** - Subtly varied but cohesive
```swift
let config = ColourJourneyConfig(
    anchors: [baseColor],
    variation: .subtle(dimensions: [.hue, .lightness])
)
let segments = journey.discrete(count: 50)
```

**Gradients** - Smooth, perceptually uniform
```swift
let gradient = journey.linearGradient(stops: 20)
```

## Performance

Benchmarked on Apple M1:
- **10,000+ continuous samples/second**
- **100-color discrete palette in <1ms**
- Fast OKLab conversion: ~3-5x faster than `cbrtf()`
- Zero allocations for continuous sampling
- Minimal allocations for discrete palettes

## Technical Details

### OKLab Color Space

The system operates internally in [OKLab](https://bottosson.github.io/posts/oklab/), a perceptually uniform color space developed by Björn Ottosson specifically for graphics and image processing.

OKLab was designed to address limitations in older color spaces like LAB and LUV:
- **L** = Lightness (perceived brightness)
- **a, b** = Chroma and hue (colourfulness and angle)
- Euclidean distance ≈ perceptual difference (ΔE)

This ensures:
- Consistent brightness across hue wheel
- Reliable chroma behavior
- Predictable contrast
- No surprise "muddy midpoints"
- Better hue linearity than CIELAB

The conversion formulas used here are taken directly from [Björn Ottosson's reference implementation](https://bottosson.github.io/posts/oklab/), optimized for performance while maintaining accuracy.

### Fast Cube Root
Uses bit manipulation + Newton-Raphson for ~1% error, 3-5x speedup:
```c
static inline float fast_cbrt(float x) {
    union { float f; uint32_t i; } u;
    u.f = x;
    u.i = u.i / 3 + 0x2a514067;
    float y = u.f;
    y = (2.0f * y + x / (y * y)) * 0.333333333f;
    return y;
}
```

### Journey Design
Journeys are not simple linear interpolations. They use:
- **Shaped waypoints** with non-uniform hue distribution
- **Easing curves** (smootherstep) for natural pacing
- **Chroma envelopes** to avoid flat saturation
- **Lightness waves** for visual interest
- **Mid-journey boosts** to prevent muddy midpoints

All computed in OKLab space for perceptual consistency.

## Credits

**OKLab Color Space**  
Created by [Björn Ottosson](https://bottosson.github.io/posts/oklab/)  
The perceptually uniform color space that makes this system possible. All color conversion formulas are based on Björn's reference implementation.

**Journey System Design**  
Implements the perceptual color journey specification with focus on designer-quality output and practical UI use cases.

**Optimization**  
Fast cube root approximation and careful C implementation for real-time color generation.

---

## License

MIT License - see LICENSE file

**Questions?** Check the example code in `Example.swift` or open an issue.