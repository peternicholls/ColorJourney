# Palette Engine Quick Start

*A 5-minute guide to using ColorJourney's palette engine for dynamic color generation.*

## What is the Palette Engine?

The **palette engine** generates perceptually-distinct color swatches on-demand. It:
- ✅ Works without knowing upfront how many colors you'll need
- ✅ Guarantees visual contrast between adjacent colors
- ✅ Uses perceptual color space (OKLab) for human-like results
- ✅ Runs in microseconds (real-time safe)
- ✅ Is deterministic (same input = same output always)

## Basic Usage

```swift
import ColorJourney

// Create a palette engine from a base color
let baseColor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))

// Get colors on-demand
let color0 = journey[0]      // First color
let color1 = journey[1]      // Second color
let color2 = journey[2]      // Third color
```

## Four Access Patterns

### 1. Single Index (Most Intuitive)

```swift
// Add elements one at a time
for i in 0..<trackCount {
    let color = journey[i]
    addTrack(name: "Track \(i)", color: color)
}
```

**Best for:** Timeline tracks, tags, progressive UI building  
**Performance:** O(n) where n = index

---

### 2. Index Method (Explicit)

```swift
// Same as subscript, but more explicit
let color = journey.discrete(at: 5)
```

**Best for:** When you want explicit intent  
**Performance:** O(n) where n = index

---

### 3. Range (Batch Access)

```swift
// Get multiple colors at once
let categoryColors = journey.discrete(range: 0..<12)

for (category, color) in zip(categories, categoryColors) {
    renderCategory(category, withColor: color)
}
```

**Best for:** Charts with N categories, grids  
**Performance:** O(start + count), more efficient than calling index multiple times  
**Bonus:** Perfect when count is known upfront

---

### 4. Lazy Sequence (Streaming)

```swift
// Infinite sequence, get what you need
let colors = journey.discreteColors.prefix(columnCount)

for (column, color) in zip(columns, colors) {
    addColumnWithColor(color)
}
```

**Best for:** Dynamic count, responsive layouts, streaming  
**Performance:** Batches internally (100-color chunks) for efficiency  
**Bonus:** Works with any prefix size, adapts to layout changes

---

## All Patterns Produce Identical Results

```swift
// These all produce the same 5 colors
let colors1 = [journey[0], journey[1], journey[2], journey[3], journey[4]]
let colors2 = [0,1,2,3,4].map { journey.discrete(at: $0) }
let colors3 = journey.discrete(range: 0..<5)
let colors4 = Array(journey.discreteColors.prefix(5))
let colors5 = journey.discrete(count: 5)

// All identical! Choose based on readability.
```

## Real-World Examples

### Timeline Editor (Progressive)

```swift
class TimelineEditor {
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    var tracks: [Track] = []
    
    func userAddsTrack(name: String) {
        let index = tracks.count
        let color = journey[index]  // Get color on-demand
        let track = Track(name: name, color: color)
        tracks.append(track)
    }
}
```

### Dashboard (Responsive)

```swift
struct DashboardView: View {
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: .vividLoop))
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var columnCount: Int {
        sizeClass == .compact ? 1 : 4
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Lazy sequence adapts to column count
            ForEach(Array(journey.discreteColors.prefix(columnCount).enumerated()), id: \.offset) { offset, color in
                ColumnView(color: color)
            }
        }
    }
}
```

### Data Visualization (Batch)

```swift
class ChartRenderer {
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: .vividLoop))
    
    func renderChart(with categories: [String]) {
        // Get all colors at once
        let colors = journey.discrete(range: 0..<categories.count)
        
        for (category, color) in zip(categories, colors) {
            drawBar(label: category, color: color)
        }
    }
}
```

## Configuration: Journey Styles

Six pre-configured styles for different moods:

```swift
let journey1 = ColorJourney(config: .singleAnchor(color, style: .balanced))        // Neutral
let journey2 = ColorJourney(config: .singleAnchor(color, style: .pastelDrift))     // Light, soft
let journey3 = ColorJourney(config: .singleAnchor(color, style: .vividLoop))       // Saturated
let journey4 = ColorJourney(config: .singleAnchor(color, style: .nightMode))       // Dark
let journey5 = ColorJourney(config: .singleAnchor(color, style: .warmEarth))       // Warm bias
let journey6 = ColorJourney(config: .singleAnchor(color, style: .coolSky))         // Cool bias
```

## Advanced: Custom Configuration

```swift
let config = ColorJourneyConfig(
    anchors: [baseColor],              // Required: seed color(s)
    lightness: .lighter,               // Make colors brighter
    chroma: .vivid,                    // Increase saturation
    contrast: .high,                   // Stronger visual separation
    temperature: .warm,                // Shift toward warm hues
    midJourneyVibrancy: 0.7,          // Boost energy at midpoint
    loopMode: .closed                  // Seamless loop
)
let journey = ColorJourney(config: config)
```

## Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| Single color `journey[i]` | O(n) | Computes colors 0..i-1 for contrast context |
| Range 10 colors | ~1ms | Efficient for batches |
| 100 colors continuous | ~10ms | Real-time safe |
| 1000 colors | ~100ms | Fine for pre-computation |

**Key Point:** No caching needed - colors are deterministic and cheap to recompute.

## Common Patterns

### Pattern A: "I add items one at a time"
```swift
for i in 0..<dynamicCount {
    color = journey[i]
}
```

### Pattern B: "I know the count upfront"
```swift
let colors = journey.discrete(range: 0..<12)
```

### Pattern C: "Screen size changes"
```swift
let colors = Array(journey.discreteColors.prefix(columnCount))
```

### Pattern D: "Mixed: batch + incremental"
```swift
// Batch load first 5
let initial = journey.discrete(range: 0..<5)

// Add more dynamically
for i in 5..<dynamicCount {
    let color = journey[i]
}
```

## Troubleshooting

**Q: Colors look similar/contrast is weak**
```swift
// Increase contrast level
config.contrast = .high  // or .custom(threshold: 0.15)
```

**Q: Want different mood/style**
```swift
// Use different style preset
.singleAnchor(color, style: .vividLoop)  // Try different styles
```

**Q: Need colors to look more varied**
```swift
// Use multi-anchor journey
let config = ColorJourneyConfig(
    anchors: [color1, color2, color3]
)
```

**Q: Want subtle variation**
```swift
// Add variation layer
config.variation = .subtle(
    dimensions: [.hue, .lightness],
    seed: 12345  // Deterministic
)
```

## Memory Usage

- Each journey: ~1 KB base
- Per color computed: Negligible (no caching by default)
- Lazy sequence buffer: ~1.2 KB (100 colors)

**Bottom line:** Memory-efficient, suitable for embedded/mobile.

## Thread Safety

⚠️ **Important:** Journey instances are not thread-safe for concurrent access due to internal caching. For multi-threaded use:

```swift
// Create one journey per thread
let journeyPerThread = [ColorJourney](repeating: journey, count: threadCount)

// Or use locks
let lock = NSLock()
lock.lock()
let color = journey[index]
lock.unlock()
```

## Next Steps

1. **Run the demo:**
   ```bash
   ./.build/release/swatch-demo
   ```

2. **Adapt to your use case:** Copy the appropriate pattern from the demo

3. **Experiment:** Try different styles and configurations

4. **Integrate:** Drop into your app and start generating palettes!

---

**Remember:** The palette engine is portable (C99 + Swift), deterministic, and optimized for real-time use. No external dependencies, no caching needed, works everywhere!
