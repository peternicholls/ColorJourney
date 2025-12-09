# ColorJourney Architecture

**Document Date**: 2025-12-08  
**Status**: Complete  
**Version**: 1.0

---

## Overview

ColorJourney is a **two-layer architecture** designed for maximum portability, performance, and ergonomics:

1. **C Core** (`CColorJourney`): High-performance color math, ~0.6μs per sample
2. **Swift Wrapper** (`ColorJourney`): Type-safe, ergonomic Swift API with preset styles

The C core ensures the system can be used anywhere—iOS, macOS, Linux, Windows, WebAssembly—while the Swift wrapper provides idiomatic APIs for Apple platforms.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Application                        │
│                                                                 │
│  (iOS/macOS/watchOS/tvOS/visionOS/C++/Python/JavaScript/etc)  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
        ┌─────────────────────┴──────────────────────┐
        │                                            │
┌───────▼──────────────┐           ┌────────────────▼─────┐
│   Swift Wrapper      │           │  C Direct (FFI/WASM) │
│  ColorJourney.swift  │           │                      │
│  ~600 lines          │           │  Via C bindings      │
│                      │           │                      │
│ • Type-safe types    │           │  (Future: JS, Py)    │
│ • Preset styles      │           │                      │
│ • SwiftUI integration│           │                      │
│ • Idiomatic API      │           │                      │
└───────┬──────────────┘           └────────────┬─────────┘
        │                                       │
        └───────────────────┬───────────────────┘
                            │
                    ┌───────▼───────────┐
                    │   C Core Library  │
                    │ ColorJourney.c/h  │
                    │   ~500 lines      │
                    │                   │
                    │ • OKLab math      │
                    │ • Journey sampling│
                    │ • Color conversion│
                    │ • PRNG variation  │
                    │ • Contrast enforce│
                    │                   │
                    │ Platform: C99     │
                    │ Performance: ~1% │
                    │  error, 3-5x fast│
                    │ Dependencies: 0   │
                    └───────────────────┘
```

---

## Layer 1: C Core Library (`Sources/CColorJourney/`)

### Purpose

High-performance color math and journey generation. The C core is the canonical implementation and must work everywhere.

### Why C?

**Principle I: Portability**
- Works on iOS, macOS, Linux, Windows, WebAssembly, embedded systems
- No language-specific runtime required
- FFI-friendly for Python, Rust, JavaScript bindings

**Principle V: Performance**
- 0.6 microseconds per color sample
- 10,000+ colors/second
- Zero allocations for continuous sampling
- Tight, optimized loop performance

**Principle IV: Determinism**
- Fully deterministic: identical inputs → identical outputs across platforms
- Seeded variation is reproducible

### Public API

**Configuration**:
- `cj_config_init()`: Initialize config with defaults
- `CJ_Config`: Structure holding all journey parameters
- `CJ_LoopMode`, `CJ_LightnessBias`, `CJ_ChromaBias`, etc.: Enums for configuration

**Journey Lifecycle**:
- `cj_journey_create()`: Allocate and initialize journey
- `cj_journey_destroy()`: Free journey resources
- `cj_journey_sample()`: Sample single color (~0.6 μs)
- `cj_journey_discrete()`: Generate N distinct colors

**Color Conversions**:
- `cj_rgb_to_oklab()`: RGB → OKLab (with fast cube root)
- `cj_oklab_to_rgb()`: OKLab → RGB
- `cj_oklab_to_lch()`: OKLab → Cylindrical (hue, chroma, lightness)
- `cj_lch_to_oklab()`: Cylindrical → OKLab

**Analysis**:
- `cj_delta_e()`: Perceptual distance in OKLab
- `cj_rgb_clamp()`: Normalize out-of-gamut colors
- `cj_is_readable()`: Check lightness suitability
- `cj_enforce_contrast()`: Adjust colors to meet ΔE threshold

### Internal Architecture

#### Configuration (CJ_Config)

```c
typedef struct {
    CJ_RGB anchors[8];       // Up to 8 anchor colors
    int anchor_count;

    CJ_LightnessBias lightness_bias;
    CJ_ChromaBias chroma_bias;
    CJ_ContrastLevel contrast_level;
    float mid_journey_vibrancy;
    CJ_TemperatureBias temperature_bias;

    CJ_LoopMode loop_mode;

    bool variation_enabled;
    uint32_t variation_dimensions;   // Bitfield
    CJ_VariationStrength variation_strength;
    uint64_t variation_seed;         // Xoshiro128+ seed
} CJ_Config;
```

#### Journey Handle (Opaque)

Internally managed:

```c
typedef struct {
    CJ_Config config;                // Input configuration
    CJ_LCh anchor_lch[8];           // Anchors in LCh (perceptual)
    
    struct { CJ_LCh anchor; float weight; } waypoints[16];
    int waypoint_count;              // Designed waypoints for journey shape
    
    CJ_RGB* discrete_cache;          // Optional cached palette
    uint64_t rng_state;              // PRNG state for deterministic variation
} CJ_Journey_Impl;
```

#### Data Flow for Single Sample

```
Input: t ∈ [0, 1], config
  │
  ├─ Handle looping (open/closed/pingpong) → t' ∈ [0, 1]
  │
  ├─ Interpolate waypoints (with smoothstep easing)
  │  Result: LCh (lightness, chroma, hue)
  │
  ├─ Apply dynamics/biases:
  │  • Lightness shift
  │  • Chroma scaling
  │  • Mid-journey vibrancy boost
  │  • Temperature hue shift
  │
  ├─ Apply variation (if enabled, deterministic seeded)
  │
  ├─ Convert LCh → OKLab → RGB
  │
  └─ Output: CJ_RGB color
```

#### Performance Optimizations

1. **Fast Cube Root**: ~1% error, 3-5x faster than `cbrtf()`
   - Bit manipulation for initial guess
   - One Newton-Raphson iteration
   - Perceptually invisible error

2. **OKLab Math**: 3-stage pipeline (RGB → LMS → LMS' → OKLab)
   - Fully inlined, no function call overhead
   - Precomputed matrices (constants)

3. **Journey Sampling**: No allocations, pure computation
   - Waypoint interpolation in LCh space
   - Shortest-path hue wrapping
   - Smoothstep easing (cubic polynomial, not transcendental)

4. **Determinism**: Seeded xoshiro128+ PRNG for variation
   - Reproducible across platforms
   - Fast (bit operations only)

### Constraints & Guarantees

**Determinism** (Constitutional Principle IV):
- Given identical config and seed, output is byte-identical across platforms
- No floating-point nondeterminism (no `fma`, no IEEE rounding issues)
- Variation is fully seeded (no true randomness)

**Performance** (Constitutional Principle V):
- Single sample: < 1 microsecond
- Discrete palette (N colors): O(N) time, linear
- Memory: O(1) for continuous sampling, ~2KB for discrete palette

**Perceptual Integrity** (Constitutional Principle II):
- All color math in OKLab (perceptually uniform)
- Fast cube root maintains < 1% error (invisible to human eye)
- Contrast enforcement ensures distinguishability

**Portability** (Constitutional Principle I):
- Pure C99, no platform-specific code
- Zero external dependencies (not even libc for core math)
- Compiles with gcc, clang, MSVC, any C99 compiler

---

## Layer 2: Swift Wrapper (`Sources/ColorJourney/`)

### Purpose

Idiomatic Swift API with type safety, preset styles, and SwiftUI integration.

### Design Principles

**Principle III: Designer-Centric**
- Sensible defaults that work "out of the box"
- Preset styles (balanced, pastel, vivid, warm, cool, night mode)
- Perceptual language (not technical: "vivid" not "1.4x chroma")

**Principle I: Portability**
- Works across all Apple platforms (iOS 13+, macOS 10.15+, etc.)
- Lightweight C interop, no platform-specific tricks

### Public API

**Configuration Types**:
- `ColorJourneyRGB`: Struct for color (r, g, b)
- `ColorJourneyConfig`: Configuration (anchors, biases, looping, variation)
- `JourneyStyle`: Preset enums (balanced, pastel, vivid, warmEarth, coolSky, etc.)
- Bias enums: `LightnessBias`, `ChromaBias`, `ContrastLevel`, `TemperatureBias`, `LoopMode`
- `VariationConfig`, `VariationDimensions`, `VariationStrength`

**Main Class**:
- `ColorJourney`: Final class wrapping C journey handle
  - `init(config:)`: Create from config
  - `sample(at:)`: Get color at parameter t
  - `discrete(count:)`: Generate N distinct colors
  - `gradient(stops:)`: SwiftUI Gradient
  - `linearGradient(...)`: SwiftUI LinearGradient

**Convenience Builders**:
- `ColorJourneyConfig.singleAnchor(..., style:)`
- `ColorJourneyConfig.multiAnchor(..., style:)`

### Internal Architecture

#### Bridging to C

```swift
// Configuration mapping (one-way C to Swift)
ColorJourneyConfig → CJ_Config

LightnessBias.lighter    → CJ_LIGHTNESS_LIGHTER
ChromaBias.vivid         → CJ_CHROMA_VIVID
ContrastLevel.high       → CJ_CONTRAST_HIGH
LoopMode.closed          → CJ_LOOP_CLOSED

VariationDimensions [.hue, .lightness] → CJ_VARIATION_HUE | CJ_VARIATION_LIGHTNESS
```

#### Presets (JourneyStyle)

Each preset is a `ColorJourneyConfig` with specific biases:

```swift
.balanced      // neutral on all: good defaults
.pastelDrift   // lighter + muted + low contrast: soft
.vividLoop     // vivid + high contrast + closed loop: bold
.nightMode     // darker: dark mode UIs
.warmEarth     // warm hue + natural chroma: earthy
.coolSky       // cool hue + lighter: airy
.custom(...)   // manual control
```

### SwiftUI Integration

**Gradient Creation**:
```swift
journey.gradient(stops: 20)              // SwiftUI Gradient
journey.linearGradient(stops: 20)        // SwiftUI LinearGradient
```

**Color Conversion**:
```swift
ColorJourneyRGB(r, g, b).color          // → SwiftUI Color
Color(journeyRGB: rgb)                   // Convenience initializer
```

### Memory Management

- Auto-allocated by `init()`, freed by `deinit`
- Zero public manual memory management
- C handle lifecycle managed via Swift ARC

---

## Data Flow Diagram

### Single Color Sample

```
User Code
  │
  └─ journey.sample(at: 0.7)
      │
      ├─ Guard handle is valid
      │
      ├─ Call C: cj_journey_sample(handle, 0.7)
      │   │
      │   ├─ Handle loop mode (clamp/wrap/reflect)
      │   ├─ Interpolate waypoints (smoothstep easing)
      │   ├─ Apply lightness/chroma/temp biases
      │   ├─ Apply mid-journey vibrancy boost
      │   ├─ Apply variation (if seeded)
      │   ├─ Convert LCh → OKLab → RGB
      │   │
      │   └─ Return CJ_RGB
      │
      └─ Wrap in ColorJourneyRGB
         │
         └─ Return to user (Swift)
```

### Discrete Palette Generation

```
User Code
  │
  └─ journey.discrete(count: 8)
      │
      ├─ Allocate buffer [8 × CJ_RGB]
      │
      ├─ Call C: cj_journey_discrete(handle, 8, buffer)
      │   │
      │   ├─ For i = 0 to 7:
      │   │   ├─ Sample at t = i/7
      │   │   ├─ Apply contrast enforcement (ΔE ≥ threshold)
      │   │   ├─ Store in buffer[i]
      │   │
      │   └─ Return
      │
      ├─ Map CJ_RGB[] → ColorJourneyRGB[]
      │
      └─ Return [ColorJourneyRGB × 8]
```

---

## Key Design Decisions

### Why OKLab?

- **Perceptual Uniformity**: Distance in OKLab correlates with human perception
- **Simplicity**: Minimal transformation stages (RGB → LMS → OKLab)
- **Accuracy**: Suitable for color-critical work
- **Reference**: Björn Ottosson's research-backed implementation

### Why Waypoint-Based Journeys?

- **Non-Linear Pacing**: Smoothstep easing for natural feel (not mechanical)
- **Designed Curves**: Chroma and lightness envelopes, not flat interpolation
- **Hue Shortest Path**: Avoids accidental rainbow effects
- **Flexibility**: Single-anchor = full wheel; multi-anchor = custom paths

### Why Seeded Variation?

- **Determinism**: Same seed = same variation (reproducible, shareable)
- **Organic Feel**: Adds perceived hand-crafted quality
- **Fast**: Xoshiro128+ is 10-100x faster than typical PRNG
- **Simple**: Minimal code, easy to understand

### Why No External Dependencies?

- **Portability**: Compiles on any C99 system
- **Reliability**: No version conflicts, no library dependencies
- **Performance**: No function call overhead, inlining control
- **Simplicity**: Self-contained, easier to audit and maintain

### Why Two Layers?

- **Separation of Concerns**: Core logic (C) vs API ergonomics (Swift)
- **Reusability**: C core usable everywhere; Swift wrapper for Apple platforms
- **Performance**: C for tight loops, Swift for convenience
- **Maintenance**: Changes to one layer don't affect the other

---

## Constraints & Trade-Offs

### Performance vs Accuracy

- **Fast Cube Root**: ~1% error for 3-5x speed gain
  - Trade-off acceptable because error is invisible to perception
  - Consistent across platforms (no IEEE variance)

- **Smoothstep Easing**: Cubic polynomial instead of transcendental
  - Good perceptual pacing without expensive math

### Simplicity vs Flexibility

- **Limited to 8 Anchors**: Keeps waypoint array fixed-size, no allocations
  - 8 anchors sufficient for practical use cases
  - Multi-anchor paths rarely use more than 4-6

- **Fixed Waypoint Count**: Internal structure fixed for performance
  - Simplifies interpolation logic
  - Matches typical UI palette sizes

### API Design

- **Immutable Config**: Journeys are immutable after creation
  - Enables caching and reuse
  - Simplifies threading (read-only)
  - C handle is opaque (no direct manipulation)

- **Type Safety Over Flexibility**: Enums instead of magic numbers
  - Swift developers can't pass invalid values
  - IDE autocomplete helps discovery
  - Compiler catches errors

---

## Testing & Validation

### C Core Testing

- **Unit Tests**: 49 tests in `Tests/CColorJourneyTests/`
  - Color conversion accuracy
  - Journey sampling correctness
  - Contrast enforcement
  - Variation determinism
  - Edge cases (dark/light, saturated/muted)

- **Stress Testing**: See `DevDocs/stress-test/`
  - 10,000-color generation
  - All loop modes
  - All bias combinations
  - Variation patterns

### Swift Wrapper Testing

- **API Tests**: 49 tests in `Tests/ColorJourneyTests/`
  - Config creation
  - Journey generation
  - Preset styles
  - SwiftUI integration
  - Error handling

### Compatibility

- **Cross-Platform**: Tested on iOS, macOS, watchOS, tvOS, visionOS
- **Determinism**: Verified identical output across platforms
- **Performance**: Benchmarked on M1, M2, Intel platforms

---

## Future Extensibility

### Potential Additions

1. **Additional Presets**: More style combinations (pastels, neons, etc.)
2. **Curve Control**: Expose waypoint customization for power users
3. **Color Analysis**: Functions to analyze journey properties
4. **Cache Management**: Explicit palette caching for frequently-used configs
5. **Export Formats**: JSON/CSV export for design tool integration

### Language Bindings

- **Python**: Via ctypes or CFFI
- **Rust**: Already portable; safe wrapper possible
- **JavaScript/WebAssembly**: Via Emscripten or wasm-bindgen
- **C++**: Native C usage in C++ projects

### Platform Extensions

- **OpenGL/Metal Shaders**: GPU implementations for real-time effects
- **GPU Compute**: SIMD vectorization for batch generation
- **GPU Texture Generation**: Dynamic texture/gradient generation

---

## References

### Internal Documentation

- [DOCUMENTATION.md](DOCUMENTATION.md) — API documentation standards and glossary
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contribution guidelines including docs
- [DevDocs/IMPLEMENTATION_STATUS.md](DevDocs/IMPLEMENTATION_STATUS.md) — Detailed status
- [DevDocs/PRD.md](DevDocs/PRD.md) — Product requirements
- [.specify/memory/constitution.md](.specify/memory/constitution.md) — Core principles

### External References

- **OKLab**: [Björn Ottosson's Blog](https://bottosson.github.io/posts/oklab/)
  - Perceptual color space definition and formulas
  - Reference implementation used here

- **Color Science**: [Bruce Lindbloom's Website](http://www.brucelindbloom.com/)
  - Color conversion references
  - RGB, Lab, LCh definitions

- **PRNG**: [Xoshiro/Xoroshiro Generators](https://prng.di.unimi.it/)
  - Fast, simple PRNG suitable for graphics
  - Xoshiro128+ used for seeded variation

### Related Literature

- **Perceptual Color**: [Just Noticeable Differences (JND)](https://en.wikipedia.org/wiki/Just-noticeable_difference)
- **Color Psychology**: [Color Theory Fundamentals](https://en.wikipedia.org/wiki/Color_theory)
- **Numerical Methods**: [Newton-Raphson Iteration](https://en.wikipedia.org/wiki/Newton%27s_method)

---

## Summary

ColorJourney's architecture balances **portability**, **performance**, **determinism**, and **designer-friendly ergonomics**. The two-layer design ensures the C core is universally usable while the Swift wrapper provides idiomatic APIs for Apple platforms. All design decisions are grounded in the four Constitutional Principles: Portability, Perceptual Integrity, Designer-Centric Design, and Determinism.

For detailed API documentation, see [DOCUMENTATION.md](DOCUMENTATION.md).
For implementation status and decision logs, see [DevDocs/](DevDocs/).
