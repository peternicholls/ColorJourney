# ColorJourney: Quick Reference Card

A one-page guide to accessing the color palette.

---

## The Two Ways to Get Colors

### 🎨 Pattern 1: Continuous Sampling (Gradients)

**When:** Smooth transitions, animations, gradients, time-based data

```swift
let journey = ColorJourney(config: .singleAnchor(color, style: .balanced))

// Single sample
let color = journey.sample(at: 0.5)  // Mid-journey color

// Create gradient
let gradient = journey.linearGradient(stops: 20)
Rectangle().fill(gradient)

// Animate (each frame)
let t = animationProgress  // 0.0 to 1.0
let frameColor = journey.sample(at: t)
```

**Output:** Infinitely smooth color transition  
**Speed:** ~0.6 microseconds per sample  
**Memory:** Zero allocations per sample  
**Good for:** Smooth UI, animations, streaming data

---

### 📊 Pattern 2: Discrete Palette (Indexed Colors)

**When:** Categories, labels, list items, tracks, legend

```swift
let journey = ColorJourney(config: .singleAnchor(color, style: .balanced))

// Generate N distinct colors
let palette = journey.discrete(count: 10)

// Access by index
let track1Color = palette[0]
let track5Color = palette[4]

// For more items than colors, cycle
let track99Color = palette[99 % palette.count]

// Iterate
for (i, color) in palette.enumerated() {
    myItems[i].backgroundColor = color.uiColor
}
```

**Output:** Array of N pre-computed colors  
**Speed:** ~0.1ms for 100 colors  
**Guarantee:** Minimum perceptual contrast (OKLab ΔE)  
**Good for:** UI lists, categories, fixed assignments

---

## Quick Configuration

### Basic Setup
```swift
// Simple: single color, preset style
let config = ColorJourneyConfig.singleAnchor(
    ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8),
    style: .balanced
)
let journey = ColorJourney(config: config)
```

### Advanced: Control Everything
```swift
var config = ColorJourneyConfig(
    anchors: [color1, color2, color3],        // Multi-anchor
    lightness: .lighter,                       // Brighter
    chroma: .vivid,                            // More saturated
    contrast: .high,                           // Strong distinction
    midJourneyVibrancy: 0.7,                   // Enhance midpoint
    temperature: .warm,                        // Warm bias
    loopMode: .closed,                         // Seamless loop
    variation: .subtle(dimensions: [.hue], seed: 42)  // Deterministic variation
)
let journey = ColorJourney(config: config)
```

### 6 Preset Styles
```swift
.balanced      // Neutral, versatile
.pastelDrift   // Light, muted, soft
.vividLoop     // Saturated, high contrast, closed loop
.nightMode     // Dark, subdued
.warmEarth     // Warm bias, natural
.coolSky       // Cool bias, light
```

---

## Converting to Platform Colors

```swift
let rgb = ColorJourneyRGB(r: 0.5, g: 0.6, b: 0.7)

// SwiftUI
let color = rgb.color

// UIKit
let uiColor = rgb.uiColor

// AppKit
let nsColor = rgb.nsColor
```

---

## Common Use Cases

### Timeline Tracks (Multiple Colors)
```swift
let trackColors = journey.discrete(count: 12)
for (i, track) in tracks.enumerated() {
    track.color = trackColors[i].uiColor
}
```

### Progress Bar (Continuous Color)
```swift
let t = progress / 100.0  // 0.0 to 1.0
let color = journey.sample(at: Float(t))
progressView.tintColor = color.uiColor
```

### Data Categories (Cycling)
```swift
let categoryColors = journey.discrete(count: 6)
for (i, item) in items.enumerated() {
    item.color = categoryColors[i % categoryColors.count].color
}
```

### Gradient Background
```swift
Rectangle()
    .fill(journey.linearGradient(stops: 20))
    .frame(height: 200)
```

### Smooth Animation
```swift
Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
    let t = Float(Date().timeIntervalSince1970).truncatingRemainder(dividingBy: 2.0) / 2.0
    view.backgroundColor = journey.sample(at: t).uiColor
}
```

---

## Configuration Options at a Glance

| Option | Type | Values | Default |
|--------|------|--------|---------|
| **Lightness** | `LightnessBias` | `.neutral`, `.lighter`, `.darker`, `.custom(weight)` | `.neutral` |
| **Chroma** | `ChromaBias` | `.neutral`, `.muted`, `.vivid`, `.custom(mult)` | `.neutral` |
| **Contrast** | `ContrastLevel` | `.low`, `.medium`, `.high`, `.custom(ΔE)` | `.medium` |
| **Vibrancy** | `Float` | [0.0 to 1.0] | 0.3 |
| **Temperature** | `TemperatureBias` | `.neutral`, `.warm`, `.cool` | `.neutral` |
| **Loop Mode** | `LoopMode` | `.open`, `.closed`, `.pingPong` | `.open` |
| **Variation** | `VariationConfig` | Enabled/disabled, per-dimension, strength, seed | Off |

---

## Performance Benchmarks

| Operation | Time | Memory |
|-----------|------|--------|
| Single `sample(at: t)` | ~0.6 μs | 0 bytes |
| 10 samples | ~6 μs | 0 bytes |
| 1000 samples | ~600 μs | 0 bytes |
| `discrete(count: 10)` | ~0.01 ms | ~200 bytes |
| `discrete(count: 100)` | ~0.1 ms | ~2 KB |
| `linearGradient(stops: 20)` | ~1 ms | ~1 KB |

---

## Real Code Example

```swift
import SwiftUI
import ColorJourney

struct ContentView: View {
    let baseColor = ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8)
    
    var body: some View {
        VStack {
            // Gradient example
            Rectangle()
                .fill(
                    ColorJourney(
                        config: .singleAnchor(baseColor, style: .balanced)
                    )
                    .linearGradient(stops: 20)
                )
                .frame(height: 100)
            
            // Discrete palette example
            let palette = ColorJourney(
                config: .singleAnchor(baseColor, style: .vividLoop)
            ).discrete(count: 5)
            
            HStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(palette[i].color)
                }
            }
        }
    }
}
```

---

## Key Facts

✅ **Fully deterministic** – Same config → same colors (no surprises)  
✅ **OKLab-based** – Perceptually uniform (consistent brightness & saturation)  
✅ **Fast** – 10,000+ colors/sec (optimized C core)  
✅ **Portable** – Works on iOS, macOS, watchOS, tvOS, visionOS  
✅ **Tested** – 49 comprehensive tests, 100% passing  
✅ **Type-safe** – Full Swift, discoverable API  
✅ **No magic** – Deterministic variation (seeded PRNG)  

---

## When to Use Which Pattern?

```
Do you have continuous data (0–100)?
├─ YES → Use continuous: sample(at: normalized)
└─ NO  → Use discrete: palette[categoryIndex]

Need smooth gradient?
├─ YES → Use continuous or linearGradient()
└─ NO  → Use discrete

Items exceed palette size?
├─ YES → Use cycling: palette[i % palette.count]
└─ NO  → Use discrete directly
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Colors look too similar | Increase contrast (`.high`), or increase vibrancy |
| Too dull/muddy | Increase chroma (`.vivid`), or increase vibrancy |
| Need more colors | Generate larger palette: `discrete(count: 50)` |
| Colors cycling visibly | Use `discrete()` to get more unique colors |
| Need consistent behavior | Always provide same `config` & optional `seed` |

---

## Design Philosophy: Universal Portability

ColorJourney's C99 core is **designed for universal use:**

- **Anywhere:** iOS, macOS, Linux, Windows, embedded, game engines, browsers
- **By Anyone:** Swift, Python, Rust, JavaScript, C++, or any language with C FFI
- **Forever:** Zero external dependencies, pure C99, 20+ year stability guarantee

The Swift wrapper provides modern ergonomics, but the core logic is universally available to any project, any platform, forever.

## Summary

**Continuous:** `sample(at: t)` → one color at parameter t ∈ [0,1]  
**Discrete:** `discrete(count: n)` → array of n indexed colors  
**SwiftUI:** `.gradient()` or `.linearGradient()` → ready-made gradients  
**Config:** Specify intent (lighter, vivid, warm) → not RGB math  
**Output:** `ColorJourneyRGB` → convert to `.uiColor`, `.nsColor`, or `.color`  
**Core:** C99 – compiles anywhere, runs anywhere, lasts forever  

That's all you need to know! 🎨
