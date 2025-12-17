# 004 Incremental Creation - Quick Start

This guide shows you how to use the incremental color swatch generation API to generate colors on-demand without knowing the total count in advance.

---

## Installation

Already installed if you have ColorJourney:

```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/peternicholls/ColorJourney.git", from: "2.0.0")
]
```

```ruby
# CocoaPods
pod 'ColorJourney', '~> 2.0'
```

---

## Basic Usage

### Swift Example: One-at-a-Time

```swift
import ColorJourney

// Create a journey
let journey = ColorJourney(
    anchors: [
        ColorJourneyAnchor(red: 1.0, green: 0.3, blue: 0.0, position: 0.0),
        ColorJourneyAnchor(red: 0.3, green: 0.5, blue: 0.8, position: 1.0)
    ],
    contrast: .medium
)

// Get colors incrementally using subscript
let color0 = journey[0]  // First color
let color1 = journey[1]  // Second color  
let color2 = journey[2]  // Third color

// Same index always returns same color (deterministic)
assert(journey[0] == color0)
```

### Swift Example: Dynamic Loop

```swift
// Generate colors as needed in a loop
for i in 0..<userElementCount {
    let color = journey[i]
    assignColor(to: elements[i], color: color)
}
```

### Swift Example: Lazy Sequence

```swift
// Stream colors using lazy sequence
for (index, color) in journey.discreteColors.prefix(10).enumerated() {
    print("Color \(index): R=\(color.red) G=\(color.green) B=\(color.blue)")
}
```

---

## C Example

```c
#include <CColorJourney.h>

// Create journey
CJ_Journey journey = cj_journey_create(...);

// Get individual colors
CJ_RGB color0 = cj_journey_discrete_at(journey, 0);
CJ_RGB color1 = cj_journey_discrete_at(journey, 1);
CJ_RGB color2 = cj_journey_discrete_at(journey, 2);

// Or get a range efficiently
CJ_RGB colors[10];
cj_journey_discrete_range(journey, 0, 10, colors);

// Clean up
cj_journey_destroy(&journey);
```

---

## API Reference

### Swift

```swift
// Index access (O(n) where n = index)
func discrete(at index: Int) -> ColorJourneyRGB

// Range access (O(start + count) - more efficient for batches)
func discrete(range: Range<Int>) -> [ColorJourneyRGB]

// Subscript convenience
subscript(index: Int) -> ColorJourneyRGB { get }

// Lazy sequence (uses range access internally)
var discreteColors: AnySequence<ColorJourneyRGB>
```

### C

```c
// Get single color at index (O(n) where n = index)
CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index);

// Get range of colors (O(start + count))
void cj_journey_discrete_range(CJ_Journey journey, int start, int count, CJ_RGB* out_colors);

// Spacing constant (t = index * spacing)
#define CJ_DISCRETE_DEFAULT_SPACING 0.05f
```

---

## Real-World Examples

### Example 1: Dynamic Tag System

```swift
class TagManager {
    let journey: ColorJourney
    var tags: [String] = []
    
    func addTag(_ tag: String) {
        let index = tags.count
        tags.append(tag)
        let color = journey[index]  // Get next color
        updateUI(tag: tag, color: color)
    }
}
```

### Example 2: Timeline Editor

```swift
class Timeline {
    let journey: ColorJourney
    var tracks: [Track] = []
    
    func addTrack() {
        let index = tracks.count
        let track = Track(color: journey[index])
        tracks.append(track)
    }
}
```

### Example 3: Responsive Grid

```swift
func updateGrid(columnCount: Int) {
    let colors = journey.discrete(range: 0..<columnCount)
    for (column, color) in zip(columns, colors) {
        column.backgroundColor = color.cgColor
    }
}
```

---

## Performance Tips

### ✅ Best Practices

**Sequential Access:** Use range or lazy sequence
```swift
// Good: O(n) total for n colors
let colors = journey.discrete(range: 0..<100)
```

**Batch Operations:** Use range access
```swift
// Good: Single call gets 10 colors efficiently
let batch = journey.discrete(range: start..<start+10)
```

**Caching:** Implement if needed
```swift
// For frequent random access, cache results
var colorCache: [Int: ColorJourneyRGB] = [:]

func getColor(at index: Int) -> ColorJourneyRGB {
    if let cached = colorCache[index] {
        return cached
    }
    let color = journey[index]
    colorCache[index] = color
    return color
}
```

### ⚠️ Avoid

**Random High Indices:** Can be slow due to O(n) complexity
```swift
// Slow: O(1000) to compute color 1000
let color = journey[1000]

// Better: Get range if accessing multiple
let colors = journey.discrete(range: 990..<1010)
```

---

## Key Properties

### Deterministic
Same index always returns the same color:
```swift
assert(journey[5] == journey[5])  // Always true
```

### Consistent
Different access methods return identical colors:
```swift
let indexColor = journey[3]
let rangeColor = journey.discrete(range: 3..<4)[0]
assert(indexColor == rangeColor)  // Always true
```

### Contrast-Enforced
Adjacent colors respect minimum perceptual distance:
```swift
// Configured with .medium contrast
let c1 = journey[0]
let c2 = journey[1]
let deltaE = calculateDeltaE(c1, c2)
assert(deltaE >= 0.1)  // MEDIUM threshold
```

---

## Common Patterns

### Pattern 1: Progressive UI Building

```swift
func addElement() {
    let index = elements.count
    let element = Element(color: journey[index])
    elements.append(element)
}
```

### Pattern 2: Streaming Data

```swift
func processDataStream<S: Sequence>(_ data: S) {
    for (item, color) in zip(data, journey.discreteColors) {
        process(item, withColor: color)
    }
}
```

### Pattern 3: Paginated Colors

```swift
func loadPage(_ page: Int, itemsPerPage: Int) {
    let start = page * itemsPerPage
    let colors = journey.discrete(range: start..<start+itemsPerPage)
    updateUI(with: colors)
}
```

---

## Testing

All incremental APIs have comprehensive test coverage:

```bash
# Run Swift tests
swift test --filter ColorJourneyTests

# Run C tests  
make test-c
```

**Test Coverage:**
- ✅ Determinism (same index → same color)
- ✅ Consistency (range matches individual calls)
- ✅ Contrast enforcement
- ✅ Edge cases (negative indices, empty ranges)

---

## Full Documentation

- **Specification:** [spec.md](spec.md)
- **Technical Plan:** [plan.md](plan.md)
- **Code Review:** [DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md](../../DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md)
- **Full Design Doc:** [DevDocs/archived/INCREMENTAL_SWATCH_SPECIFICATION.md](../../DevDocs/archived/INCREMENTAL_SWATCH_SPECIFICATION.md)
- **Demo:** [Examples/SwatchDemo/](../../Examples/SwatchDemo/)

---

## Need Help?

- Check the [specification](spec.md) for detailed requirements
- See [Examples/SwatchDemo/](../../Examples/SwatchDemo/) for a complete CLI demo
- Review test files for usage patterns
