# Color Journey

**Programmatically created graduated color palettes *that actually look good!***

[![Build Status](https://github.com/peternicholls/ColorJourney/actions/workflows/core-ci.yml/badge.svg?branch=develop)](https://github.com/peternicholls/ColorJourney/actions/workflows/core-ci.yml)
[![Version](https://img.shields.io/github/v/release/peternicholls/ColorJourney)](https://github.com/peternicholls/ColorJourney/releases)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2013%2B%20%7C%20macOS%2010.15%2B-informational)](README.md#platform-support)

## The Problem

Let's say, you need 12 distinct colors for timeline tracks. Or 8 category labels. Or a smooth gradient that doesn't turn to mud in the middle.

The usual approaches fail:
- **Linear RGB interpolation** produces muddy, inconsistent colors that clash
- **Naive hue rotation** loses perceptual contrast—some colors scream, others vanish
- **Hand-picked palettes** can't scale, adapt, or port across platforms
- **Generic color libraries** give you primitives, not design intelligence

You end up tweaking hex values by hand, copy-pasting from design tools, or settling for "good enough."

## The Solution

*Color Journey* doesn't generate any old color pallet, it **takes you on a journey through them**.

Think of it like this: you're standing at a viewpoint (your anchor color). You want to explore the landscape of color space, but not randomly—you want an intentional path. Maybe you head toward lighter territory, or veer into warmer climates. Maybe you loop back to where you started, or ping-pong between destinations.

The system plans that route by using the **[OKLab](https://bottosson.github.io/posts/oklab/)** color space. OKLab is a color space that matches human perception. As you travel, it makes sure:
- The path curves naturally (no mechanical straight lines)
- Each stop is visibly distinct (enforced perceptual contrast)
- The journey never gets muddy or washed out (chroma and lightness management)
- Hue transitions take the shortest path (no accidental rainbow detours)
- The midpoint has energy (controlled vibrancy boosts)

You specify the high-level intent—*lighter*, *more vibrant*, *warmer*—and get back a sequence of colors that feel designed, not computed. Hand-crafted quality, generated in microseconds. Fast enough for real-time use, no need to store the pallet as it is really efficient to generate on demand: repeatable, predictable, and portable.



### What You Get

**Designer controls, not color math:**  
Configure lightness, chroma, contrast, vibrancy, and temperature instead of wrestling with RGB values or HSL angles.

**Graduated palettes with intention:**  
Colors transition smoothly along designed curves with shaped pacing—not flat linear steps.

**Perceptually uniform output:**  
Built on OKLab, ensuring consistent brightness, saturation, and contrast as you move through the palette.

**Flexible journey modes:**  
Continuous sampling for gradients, discrete stops for UI elements, seamless loops, or ping-pong reversals.

**Production-ready performance:**  
Optimized C core generates 10,000+ colors per second with deterministic, cross-platform output.

**True portability:**  
C99 core works everywhere (iOS, macOS, Linux, Windows, embedded). Swift wrapper adds ergonomic API and SwiftUI integration.

## Documentation Guide

### 📚 User & API Documentation

**Start here for using ColorJourney:**

- **[Docs/](Docs/)** — Generated API documentation
  - **[Swift API](Docs/generated/swift-docc/)** — Interactive Swift documentation (DocC)
  - **[C API](Docs/generated/doxygen/html/)** — C core documentation (Doxygen)

- **[Quick Reference](DevDocs/guides/DOCS_QUICKREF.md)** — One-page cheat sheet
- **[Examples/](Examples/)** — Working code samples (C and Swift)
- **[Quick Start](#quick-start)** — Getting started in 5 minutes

### 🛠️ Developer Documentation

**For contributing and developing ColorJourney:**

- **[DevDocs/](DevDocs/)** — Complete developer documentation
  - **[Standards](DevDocs/standards/DOCUMENTATION.md)** — Documentation standards and conventions
  - **[Architecture](DevDocs/standards/ARCHITECTURE.md)** — System design and data flow
  - **[Swift-DocC Guide](DevDocs/guides/SWIFT_DOCC_GUIDE.md)** — How to write documentation
  - **[Build System](DevDocs/guides/UNIFIED_DOCS_BUILD.md)** — Unified documentation generation
  - **[Publishing Guide](DevDocs/guides/SWIFT_DOCC_PLUGIN_GUIDE.md)** — Publishing documentation online

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Contributing guidelines
- **[Implementation Status](DevDocs/IMPLEMENTATION_STATUS.md)** — Project status and progress
- **[Stress Tests](DevDocs/stress-test/)** — Performance analysis and edge cases

### 📖 All Documentation

| Location | Purpose | Audience |
|----------|---------|----------|
| **[Docs/](Docs/)** | Generated API docs (Swift + C) | API Users |
| **[DevDocs/](DevDocs/)** | Development resources and standards | Contributors |
| **[Examples/](Examples/)** | Working code samples | Everyone |
| **[Quick Start](#quick-start)** | Getting started guide | New Users |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Contributing process | Contributors |

---

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
  - [CocoaPods](#cocoapods)
  - [Make (C users)](#make-c-users)
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

1. **C Core (`ColorJourney.c/h`)** - High-performance color math and journey generation (~500 lines)
   - Fast OKLab conversions (~1% error, 3-5x faster than standard)
   - Perceptual distance calculations (OKLab ΔE)
   - Journey interpolation with designed waypoints
   - Discrete palette generation with contrast enforcement
   - Deterministic variation layer (xoshiro128+ PRNG)
   - Platform-agnostic, pure C99
   
2. **Swift Wrapper (`ColorJourney.swift`)** - Idiomatic Swift API (~600 lines)
   - Type-safe configuration with value types
   - SwiftUI/AppKit/UIKit integration
   - Preset journey styles (6 pre-configured)
   - Discoverable, chainable API
   - Automatic C↔Swift bridging

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

- **Perceptually Uniform** - Built on OKLab for consistent lightness, chroma, and hue

- **Designer-Quality** - Non-linear journeys with shaped curves, not mechanical gradients  

- **Flexible Configuration** - Single or multi-anchor, open/closed/ping-pong modes

- **High-Level Controls** - Lightness, chroma, contrast, temperature, vibrancy biases

- **Variation Layer** - Optional subtle, structured micro-variation

- **Deterministic** - Repeatable output with optional seeded variation

- **Fast** - Optimized C core processes 10,000+ colors/second

- **Portable** - Core C library works anywhere (iOS, macOS, Linux, Windows)


## Quick Start

### Basic Usage

```swift
import ColorJourney

// Create a journey from a single anchor color
let journey = ColorJourney(
    config: .singleAnchor(
        ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8),
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
let config = ColorJourneyConfig(
    anchors: [
        ColorJourneyRGB(r: 1.0, g: 0.3, b: 0.3),
        ColorJourneyRGB(r: 0.3, g: 1.0, b: 0.3),
        ColorJourneyRGB(r: 0.3, g: 0.3, b: 1.0)
    ],
    loopMode: .closed
)

let journey = ColorJourney(config: config)
```

### With Variation

```swift
let config = ColorJourneyConfig(
    anchors: [baseColor],
    variation: .subtle(
        dimensions: [.hue, .lightness],
        seed: 12345  // Deterministic
    )
)
```

### Advanced Configuration

```swift
let config = ColorJourneyConfig(
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
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.9),
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

## Examples

Complete working examples are provided in the `Examples/` directory:

**[CExample.c](Examples/CExample.c)** — Demonstrates the C API:
- Single-anchor journey setup
- Discrete palette generation
- Continuous sampling
- Memory management (create/destroy)
- Seeded variation with determinism verification
- Compiles with: `gcc -std=c99 -Wall -lm Examples/CExample.c Sources/CColorJourney/ColorJourney.c -I Sources/CColorJourney/include -o example`

**[SwiftExample.swift](Examples/SwiftExample.swift)** — Comprehensive Swift examples:
- Basic and multi-anchor journeys
- Style presets (6 presets demonstrated)
- Variation modes (off, subtle, noticeable)
- Continuous sampling (gradient generation)
- Discrete palettes (UI element colors)
- Advanced configuration patterns
- Real-world use cases (timeline tracks, labels, segments)
- Performance benchmarking

**[DocstringValidation.swift](Examples/DocstringValidation.swift)** — Validates all doc comment code snippets:
- 9 separate validation tests
- Ensures copy-paste examples actually work
- Demonstrates API patterns from documentation

Run all example verifications with:
```bash
make verify-examples    # Compile and run C and Swift examples
```

## Building 

### Xcode Project

1. Add both files to your Xcode project:
   - `ColorJourney.h`
   - `ColorJourney.c`
   - `ColorJourney.swift`

2. Create a bridging header if needed:
```objc
// YourProject-Bridging-Header.h
#include "ColorJourney.h"
```

3. Build and run

### Swift Package Manager

```swift
// Package.swift
let package = Package(
    name: "ColorJourney",
    products: [
        .library(name: "ColorJourney", targets: ["ColorJourney"])
    ],
    targets: [
        .target(
            name: "CColorJourney",
            path: "Sources/CColorJourney",
            sources: ["ColorJourney.c"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "ColorJourney",
            dependencies: ["CColorJourney"],
            path: "Sources/ColorJourney"
        )
    ]
)
```

### CocoaPods

```ruby
# Add to your Podfile:
platform :ios, '13.0'

target 'MyApp' do
  pod 'ColorJourney', '~> 1.0'
end
```

Then run:
```bash
pod install
```

**Version pinning options:**

```ruby
# Latest version within major version 1
pod 'ColorJourney', '~> 1.0'

# Specific version
pod 'ColorJourney', '1.0.2'

# Latest version (may have breaking changes)
pod 'ColorJourney'
```

**Usage:**
```swift
import ColorJourney

let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
let palette = journey.discrete(count: 8)
```

**Platform support:** iOS 13.0+, macOS 10.15+, tvOS 13.0+, watchOS 6.0+, visionOS 1.0+

**Keeping up to date:**
- Check [CHANGELOG.md](CHANGELOG.md) for breaking changes before updating
- Use semantic versioning for safe updates: `pod 'ColorJourney', '~> 1.0'`
- See [Quickstart](specs/003-cocoapods-release/quickstart.md) for detailed installation and troubleshooting

### Make (C users)

```bash
# Build static library with gcc/clang
make lib

# Then link in your project
gcc -std=c99 -I Sources/CColorJourney/include \
    myapp.c .build/gcc/libcolorjourney.a -lm -o myapp

# Build and run the sample C program
make example
./.build/gcc/example

# Build and run C core tests
make test-c
```

Artifacts land in `.build/gcc/`:
- `.build/gcc/libcolorjourney.a` – static library
- `.build/gcc/ColorJourney.o` – object file

Include `Sources/CColorJourney/include` on your header search path to use `ColorJourney.h` in C or Objective-C projects.

### Standalone C Library
```bash
# Compile C library
gcc -O3 -ffast-math -march=native -c ColorJourney.c -o ColorJourney.o

# Create static library
ar rcs libcolourjourney.a ColorJourney.o

# Or compile with your project
gcc -O3 -ffast-math myapp.c ColorJourney.c -lm -o myapp
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
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
let trackColors = journey.discrete(count: 12)
```

**Label System** - High-contrast categorical colors
```swift
let config = ColorJourneyConfig(
    anchors: [color1, color2],
    contrast: .high,
    loopMode: .closed
)
let labelColors = journey.discrete(count: 8)
```

**Segment Markers** - Subtly varied but cohesive
```swift
let config = ColorJourneyConfig(
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
- **10,000+ continuous samples/second** (~0.6μs per sample)
- **100-color discrete palette in <1ms** (~0.1ms per 100 colors)
- **Fast OKLab conversion**: ~3-5x faster than `cbrtf()` using bit manipulation + Newton-Raphson
- **Zero allocations** for continuous sampling
- **Minimal allocations** for discrete palettes (~2KB per journey)
- **Cross-platform consistency**: Deterministic output on iOS, macOS, watchOS, tvOS, visionOS, Catalyst

Optimized for real-time color generation in tight loops.

## Testing

Comprehensively tested with **49 unit tests** (100% pass rate) plus C core checks:
- Single and multi-anchor journey generation
- All perceptual dynamics (lightness, chroma, contrast, temperature, vibrancy)
- All loop modes (open, closed, ping-pong)
- Variation layer with deterministic seeding
- Discrete and continuous generation
- Edge cases and boundary conditions
- SwiftUI integration
- Performance benchmarks

Test layout:
- Swift API tests: Tests/ColorJourneyTests
- C core tests: Tests/CColorJourneyTests (run with `make test-c`)

Run tests with: `swift test`

## Platform Support

Cross-platform support with unified API:
- ✅ **iOS 13+**
- ✅ **macOS 10.15+**
- ✅ **watchOS 6+**
- ✅ **tvOS 13+**
- ✅ **visionOS 1+**
- ✅ **Catalyst 13+**

Core C library also compiles on Linux and Windows via standard C99.

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
- **Designed waypoints** with non-uniform hue distribution (not naive uniform steps)
- **Easing curves** (smoothstep) for natural, non-mechanical pacing
- **Chroma envelopes** that follow parametric curves to avoid flat saturation
- **Lightness waves** for visual interest and perceptual balance
- **Mid-journey boosts** controlled by vibrancy parameter to prevent muddy midpoints
- **Shortest-path hue wrapping** to avoid unintended long rotations

All computed in OKLab space for perceptual consistency and predictable behavior.

### Contrast Enforcement
Discrete palettes automatically enforce minimum perceptual separation:
- Computes OKLab ΔE (perceptual distance) between adjacent colors
- Adjusts lightness and chroma in small nudges if threshold not met
- Respects configured contrast level (low/medium/high/custom)
- Preserves overall palette character while maintaining readability

## Credits

**OKLab Color Space**  
Created by [Björn Ottosson](https://bottosson.github.io/posts/oklab/)  
The perceptually uniform color space that makes this system possible. All color conversion formulas are based on Björn's reference implementation.

**Journey System Design**  
Implements the perceptual color journey specification with focus on designer-quality output and practical UI use cases.

**Optimization**  
Fast cube root approximation and careful C implementation for real-time color generation.

## Implementation Notes

The implementation follows the [OKLab-Based Design Brief](DevDocs/PRD.md) which documents the complete system specification including:
- Five core conceptual dimensions (route/journey, dynamics, granularity, looping, variation)
- Perceptual guarantees and behavioral requirements
- Design principles for generating intentional, curated palettes

For detailed implementation specifics, see:
- `DevDocs/IMPLEMENTATION_STATUS.md` - Architecture and design decisions
- `DevDocs/PRD.md` - Complete product specification
- `Examples/ExampleUsage.swift` - Real-world usage scenarios

---

## License

Copyright © 2025 Peter Nicholls
This project is licensed under the MIT License - see LICENSE file for details.

Some parts based on OKLab by copyright © Björn Ottosson, used under the MIT License.

**Questions?** Check the example code in `Examples/ExampleUsage.swift`, review `DevDocs/IMPLEMENTATION_STATUS.md`, or open an issue.
