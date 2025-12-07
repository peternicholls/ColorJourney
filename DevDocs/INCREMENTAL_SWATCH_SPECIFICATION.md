# Incremental Color Swatch Generation Specification

**Status:** Draft Specification  
**Date:** December 7, 2025  
**Purpose:** Define API patterns for generating color swatches incrementally when the total count is not known in advance

---

## Problem Statement

The current ColorJourney API requires users to specify the exact number of colors needed upfront:

```c
// Current C API
CJ_RGB palette[5];
cj_journey_discrete(journey, 5, palette);

// Current Swift API
let colors = journey.discrete(count: 10)
```

This works well when the number of colors is known in advance, but fails in scenarios where:

1. **Progressive UI building** - Adding UI elements dynamically (timeline tracks, categories, labels)
2. **User-driven expansion** - Users add items one at a time (tags, labels, segments)
3. **Streaming data** - Processing data where the final count emerges over time
4. **Interactive design** - Designers exploring color options incrementally
5. **Responsive layouts** - Column counts change with screen size, requiring more/fewer colors

### Example Use Cases

**Timeline Editor:**
```
User creates track 1 → need color 1
User creates track 2 → need color 2
User creates track 3 → need color 3
...continuing as needed
```

**Tag System:**
```
Document starts with tags: ["Swift", "iOS"]
User adds "Design" → need 3rd color
User adds "Performance" → need 4th color
Each addition requires one more color
```

**Dynamic Dashboard:**
```
Screen size changes → number of visible columns changes
Need colors on-demand without regenerating entire palette
```

---

## Design Goals

### Primary Goals

1. **Simplicity for API Users** - Minimize cognitive overhead and code complexity
2. **Consistency** - Colors at index N should be identical whether generated incrementally or in batch
3. **Performance** - Avoid unnecessary recomputation when generating subsequent colors
4. **Stateless Where Possible** - Minimize client state management burden
5. **C-First Design** - Pure C99 implementation with zero external dependencies
6. **Swift-Friendly** - Natural Swift wrapper with idiomatic patterns

### Non-Goals

1. Not attempting to solve color caching across app sessions
2. Not providing color animation or transitions (out of scope)
3. Not supporting retroactive palette modification (colors are immutable once generated)

---

## Design Exploration

### Approach 1: Stateless Index-Based Access

**Concept:** Treat the journey as an infinite addressable sequence where any index can be sampled independently.

#### C API Design

```c
/* Get a single discrete color at specific index */
CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index);

/* Get a range of discrete colors [start, start+count) */
void cj_journey_discrete_range(CJ_Journey journey, 
                                int start, 
                                int count, 
                                CJ_RGB* out_colors);
```

#### Usage Example

```c
CJ_Journey journey = cj_journey_create(&config);

// Get colors one at a time as needed
CJ_RGB color0 = cj_journey_discrete_at(journey, 0);  // First color
CJ_RGB color1 = cj_journey_discrete_at(journey, 1);  // Second color
CJ_RGB color2 = cj_journey_discrete_at(journey, 2);  // Third color

// Or get a batch when count becomes known
CJ_RGB batch[5];
cj_journey_discrete_range(journey, 3, 5, batch);  // Colors 3-7

cj_journey_destroy(journey);
```

#### Swift API Design

```swift
extension ColorJourney {
    /// Get a single discrete color at the specified index
    func discrete(at index: Int) -> ColorJourneyRGB
    
    /// Get a range of discrete colors
    func discrete(range: Range<Int>) -> [ColorJourneyRGB]
    
    /// Subscript access for natural syntax
    subscript(index: Int) -> ColorJourneyRGB { get }
}
```

#### Swift Usage Example

```swift
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))

// Index-based access
let firstColor = journey.discrete(at: 0)
let secondColor = journey.discrete(at: 1)

// Or subscript syntax
let thirdColor = journey[2]

// Range access
let colors3to7 = journey.discrete(range: 3..<8)

// Progressive collection building
var trackColors: [ColorJourneyRGB] = []
for trackIndex in 0..<dynamicTrackCount {
    trackColors.append(journey[trackIndex])
}
```

#### Advantages

✅ **Zero client state** - No iterator objects to manage  
✅ **Perfect consistency** - `discrete(at: N)` always returns same color  
✅ **Random access** - Can generate color 100 without computing 0-99  
✅ **Simple mental model** - Journey is an infinite array of colors  
✅ **Cache-friendly** - Implementation can cache internally without exposing complexity  
✅ **Thread-safe** - No mutable iteration state  

#### Disadvantages

❌ **Potential redundant computation** - Computing same color multiple times if not cached  
❌ **Cache management** - Internal caching adds complexity to implementation  

#### Implementation Strategy

```c
/* Internal implementation approach */
typedef struct CJ_Journey_Impl {
    // ... existing fields ...
    
    /* Lazy cache for discrete colors */
    CJ_RGB* discrete_cache;
    int discrete_cache_size;
} CJ_Journey_Impl;

CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    
    /* Check cache first */
    if (index < j->discrete_cache_size) {
        return j->discrete_cache[index];
    }
    
    /* Expand cache if needed */
    if (index >= j->discrete_cache_size) {
        int new_size = index + 1;
        CJ_RGB* new_cache = realloc(j->discrete_cache, 
                                     new_size * sizeof(CJ_RGB));
        
        /* Generate missing colors */
        for (int i = j->discrete_cache_size; i < new_size; i++) {
            float t = (float)i / (float)(new_size - 1);
            /* Apply same discrete palette logic as cj_journey_discrete */
            new_cache[i] = compute_discrete_color(j, i, new_size);
        }
        
        j->discrete_cache = new_cache;
        j->discrete_cache_size = new_size;
    }
    
    return j->discrete_cache[index];
}
```

**Key Implementation Concern:** The `t` parameter calculation depends on total count. For index `i` in a palette of `N` colors, `t = i / (N-1)`. But if we don't know `N` in advance, how do we calculate `t`?

**Solution Options:**

1. **Assumed Maximum:** Assume a large maximum (e.g., 1000) and generate `t = i / 999`
2. **Dynamic Recalculation:** Recalculate positions when cache grows (breaks consistency)
3. **Fixed Spacing:** Use fixed `t` increments (e.g., `t = i * 0.01`) regardless of total

**Recommended:** Option 3 with a sensible default spacing that provides good perceptual distribution.

---

### Approach 2: Iterator-Based Generation

**Concept:** Provide an iterator object that maintains position state and generates colors sequentially.

#### C API Design

```c
/* Opaque iterator handle */
typedef struct CJ_DiscreteIterator_Impl* CJ_DiscreteIterator;

/* Create an iterator for discrete color generation */
CJ_DiscreteIterator cj_discrete_iterator_create(CJ_Journey journey);

/* Get next color from iterator */
bool cj_discrete_iterator_next(CJ_DiscreteIterator iter, CJ_RGB* out_color);

/* Reset iterator to beginning */
void cj_discrete_iterator_reset(CJ_DiscreteIterator iter);

/* Get current index */
int cj_discrete_iterator_index(CJ_DiscreteIterator iter);

/* Destroy iterator */
void cj_discrete_iterator_destroy(CJ_DiscreteIterator iter);
```

#### Usage Example

```c
CJ_Journey journey = cj_journey_create(&config);
CJ_DiscreteIterator iter = cj_discrete_iterator_create(journey);

CJ_RGB color;
int track_index = 0;

// Generate colors as tracks are created
while (user_adds_track()) {
    if (cj_discrete_iterator_next(iter, &color)) {
        assign_track_color(track_index++, color);
    }
}

cj_discrete_iterator_destroy(iter);
cj_journey_destroy(journey);
```

#### Swift API Design

```swift
class DiscreteColorIterator: IteratorProtocol, Sequence {
    typealias Element = ColorJourneyRGB
    
    private let journey: ColorJourney
    private var currentIndex: Int = 0
    
    func next() -> ColorJourneyRGB? {
        let color = journey.discrete(at: currentIndex)
        currentIndex += 1
        return color
    }
    
    func reset() {
        currentIndex = 0
    }
}

extension ColorJourney {
    func makeDiscreteIterator() -> DiscreteColorIterator {
        return DiscreteColorIterator(journey: self)
    }
}
```

#### Swift Usage Example

```swift
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
var iterator = journey.makeDiscreteIterator()

// Sequential access
var trackColors: [ColorJourneyRGB] = []
for _ in 0..<dynamicTrackCount {
    if let color = iterator.next() {
        trackColors.append(color)
    }
}

// Or use Swift's Sequence protocol
let first5Colors = Array(iterator.prefix(5))
```

#### Advantages

✅ **Familiar pattern** - Iterator is a well-known abstraction  
✅ **Explicit state** - State management is visible and controllable  
✅ **Sequential optimization** - Can optimize for forward-only access  
✅ **Integration with Swift** - Works naturally with `for-in` loops  

#### Disadvantages

❌ **Additional state object** - User must manage iterator lifecycle  
❌ **No random access** - Must iterate from start to reach index N  
❌ **More complex API** - Additional types and methods to learn  
❌ **Thread-safety concerns** - Iterator state is mutable  

---

### Approach 3: Generator-Based (Lazy Sequence)

**Concept:** Expose the journey as a lazy sequence that generates colors on-demand.

#### C API Design

```c
/* Generator callback - called for each color */
typedef void (*CJ_DiscreteColorCallback)(int index, CJ_RGB color, void* userdata);

/* Generate discrete colors lazily via callback */
void cj_journey_discrete_lazy(CJ_Journey journey, 
                               int start_index,
                               int count,
                               CJ_DiscreteColorCallback callback,
                               void* userdata);
```

#### Swift API Design

```swift
extension ColorJourney {
    /// Lazy sequence of discrete colors
    var discreteColors: AnySequence<ColorJourneyRGB> {
        return AnySequence { () -> AnyIterator<ColorJourneyRGB> in
            var index = 0
            return AnyIterator {
                let color = self.discrete(at: index)
                index += 1
                return color
            }
        }
    }
}
```

#### Swift Usage Example

```swift
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))

// Lazy access with standard Swift patterns
let trackColors = journey.discreteColors.prefix(dynamicTrackCount)

// Map, filter, etc.
let brightColors = journey.discreteColors
    .prefix(20)
    .filter { $0.perceivedBrightness > 0.6 }
```

#### Advantages

✅ **Swift-native** - Uses Swift's built-in lazy evaluation  
✅ **Composable** - Works with map, filter, reduce, etc.  
✅ **Memory efficient** - No upfront allocation  

#### Disadvantages

❌ **C API complexity** - Callback pattern is awkward in C  
❌ **Limited control** - Less explicit control over generation  
❌ **Not idiomatic C** - Callbacks add complexity  

---

### Approach 4: Hybrid - Index Access + Convenience Iterator

**Concept:** Primary API is index-based (Approach 1), with optional iterator wrapper for convenience.

#### C API Design

```c
/* Primary API - stateless index access */
CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index);

/* Convenience batch access */
void cj_journey_discrete_range(CJ_Journey journey, 
                                int start, 
                                int count, 
                                CJ_RGB* out_colors);

/* Keep existing API for known-count case */
void cj_journey_discrete(CJ_Journey journey, int count, CJ_RGB* out_colors);
```

#### Swift API Design

```swift
extension ColorJourney {
    // Primary API - index access
    func discrete(at index: Int) -> ColorJourneyRGB
    subscript(index: Int) -> ColorJourneyRGB { get }
    
    // Convenience - lazy sequence
    var discreteColors: DiscreteColorSequence {
        return DiscreteColorSequence(journey: self)
    }
    
    // Existing API preserved
    func discrete(count: Int) -> [ColorJourneyRGB]
}

struct DiscreteColorSequence: Sequence {
    private let journey: ColorJourney
    
    func makeIterator() -> DiscreteColorIterator {
        return DiscreteColorIterator(journey: journey)
    }
}
```

#### Swift Usage Examples

```swift
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))

// Simple index access
let color0 = journey[0]
let color5 = journey[5]

// Lazy sequence for Swift patterns
let first10 = Array(journey.discreteColors.prefix(10))

// Traditional batch when count is known
let palette = journey.discrete(count: 8)

// Progressive building
var colors: [ColorJourneyRGB] = []
for i in 0..<trackCount {
    colors.append(journey[i])
}
```

#### Advantages

✅ **Best of both worlds** - Simple for simple cases, flexible for complex ones  
✅ **Backward compatible** - Existing `discrete(count:)` still works  
✅ **C-first** - Core is simple index access  
✅ **Swift-friendly** - Sequence protocol for functional patterns  

#### Disadvantages

❌ **More API surface** - Multiple ways to do similar things  
❌ **Documentation burden** - Need to explain when to use which approach  

---

## Recommended Solution

**Approach 4: Hybrid Index Access + Convenience Iterator**

### Rationale

1. **Simplicity:** Index-based access (`journey[i]`) is the simplest mental model
2. **C-First:** Pure C99 implementation with no state management overhead
3. **Consistency:** `journey[i]` always returns the same color, guaranteed
4. **Performance:** Internal caching prevents redundant computation
5. **Flexibility:** Users can choose access pattern (index, range, sequence, batch)
6. **Backward Compatible:** Existing `discrete(count:)` API remains unchanged

### API Specification

#### C API

```c
/* === New Functions === */

/**
 * Get a single discrete color at the specified index.
 * 
 * The color at index i is deterministic and consistent - calling this
 * function multiple times with the same index returns the same color.
 * 
 * Internally uses a lazy cache to avoid recomputation. The cache grows
 * automatically as higher indices are accessed.
 * 
 * @param journey The journey handle
 * @param index Zero-based color index (must be >= 0)
 * @return RGB color at the specified index
 * 
 * Example:
 *   CJ_RGB color0 = cj_journey_discrete_at(journey, 0);
 *   CJ_RGB color5 = cj_journey_discrete_at(journey, 5);
 */
CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index);

/**
 * Get a range of discrete colors.
 * 
 * This is more efficient than calling cj_journey_discrete_at() in a loop
 * when you need multiple sequential colors.
 * 
 * @param journey The journey handle
 * @param start Starting index (inclusive)
 * @param count Number of colors to generate
 * @param out_colors Output array (must have space for 'count' colors)
 * 
 * Example:
 *   CJ_RGB colors[5];
 *   cj_journey_discrete_range(journey, 3, 5, colors); // Get colors 3-7
 */
void cj_journey_discrete_range(CJ_Journey journey, 
                                int start, 
                                int count, 
                                CJ_RGB* out_colors);

/* === Existing Function (Unchanged) === */

/**
 * Generate N discrete colors with enforced perceptual distinction.
 * 
 * This is the optimal API when the total count is known upfront.
 * 
 * @param journey The journey handle
 * @param count Total number of colors to generate
 * @param out_colors Output array (must have space for 'count' colors)
 */
void cj_journey_discrete(CJ_Journey journey, int count, CJ_RGB* out_colors);
```

#### Swift API

```swift
extension ColorJourney {
    // MARK: - Index-Based Access (New)
    
    /// Get a single discrete color at the specified index.
    ///
    /// The color at index `i` is deterministic and consistent.
    /// Calling this method multiple times with the same index returns the same color.
    ///
    /// - Parameter index: Zero-based color index
    /// - Returns: RGB color at the specified index
    ///
    /// Example:
    /// ```swift
    /// let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    /// let firstColor = journey.discrete(at: 0)
    /// let fifthColor = journey.discrete(at: 4)
    /// ```
    func discrete(at index: Int) -> ColorJourneyRGB
    
    /// Get a range of discrete colors.
    ///
    /// This is more efficient than calling `discrete(at:)` in a loop
    /// when you need multiple sequential colors.
    ///
    /// - Parameter range: Range of indices
    /// - Returns: Array of colors for the specified range
    ///
    /// Example:
    /// ```swift
    /// let colors = journey.discrete(range: 3..<8) // Colors at indices 3, 4, 5, 6, 7
    /// ```
    func discrete(range: Range<Int>) -> [ColorJourneyRGB]
    
    /// Subscript access for discrete colors.
    ///
    /// Provides natural array-like syntax for accessing discrete colors.
    ///
    /// Example:
    /// ```swift
    /// let color0 = journey[0]
    /// let color5 = journey[5]
    /// ```
    subscript(index: Int) -> ColorJourneyRGB { get }
    
    // MARK: - Lazy Sequence Access (New)
    
    /// Lazy sequence of discrete colors.
    ///
    /// Generates colors on-demand without upfront allocation.
    /// Useful for functional programming patterns and Swift Sequence operations.
    ///
    /// Example:
    /// ```swift
    /// // Take first 10 colors
    /// let colors = Array(journey.discreteColors.prefix(10))
    ///
    /// // Filter and map
    /// let brightColors = journey.discreteColors
    ///     .prefix(20)
    ///     .filter { $0.perceivedBrightness > 0.6 }
    /// ```
    var discreteColors: DiscreteColorSequence { get }
    
    // MARK: - Batch Access (Existing, Unchanged)
    
    /// Generate N discrete colors with enforced perceptual distinction.
    ///
    /// This is the optimal API when the total count is known upfront.
    ///
    /// - Parameter count: Number of colors to generate
    /// - Returns: Array of distinct colors
    func discrete(count: Int) -> [ColorJourneyRGB]
}

/// Lazy sequence of discrete colors from a journey.
///
/// This type is returned by `ColorJourney.discreteColors` and provides
/// Swift Sequence protocol conformance for functional patterns.
public struct DiscreteColorSequence: Sequence {
    private let journey: ColorJourney
    
    public func makeIterator() -> DiscreteColorIterator {
        DiscreteColorIterator(journey: journey)
    }
}

/// Iterator for discrete colors.
public struct DiscreteColorIterator: IteratorProtocol {
    private let journey: ColorJourney
    private var currentIndex: Int = 0
    
    public mutating func next() -> ColorJourneyRGB? {
        let color = journey.discrete(at: currentIndex)
        currentIndex += 1
        return color
    }
}
```

### Implementation Details

#### Color Position Calculation

**Challenge:** In the standard `discrete(count:)` API, color positions are calculated as:
```c
float t = (float)i / (float)(count - 1);
```

This ensures colors span `[0, 1]` evenly. But with unknown total count, we need a different approach.

**Solution:** Use a fixed spacing that provides good perceptual distribution:

```c
#define CJ_DISCRETE_DEFAULT_SPACING 0.05f  /* ~20 colors per full journey */

static float discrete_position(int index) {
    /* Map index to [0, 1] with diminishing spacing to avoid bunching */
    /* Using a logarithmic-like curve for better distribution */
    
    if (index == 0) return 0.0f;
    
    /* Simple linear spacing with reasonable density */
    float t = index * CJ_DISCRETE_DEFAULT_SPACING;
    
    /* Wrap around for large indices (supports unlimited colors) */
    return fmodf(t, 1.0f);
}
```

**Alternative:** Allow configuration of spacing:

```c
/* Extended config option */
typedef struct {
    // ... existing fields ...
    
    float discrete_spacing;  /* Default: 0.05, Range: [0.01, 0.2] */
} CJ_Config;
```

#### Caching Strategy

```c
typedef struct CJ_Journey_Impl {
    // ... existing fields ...
    
    /* Discrete color cache */
    CJ_RGB* discrete_cache;
    int discrete_cache_capacity;
    int discrete_cache_size;
} CJ_Journey_Impl;

CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    
    if (index < 0) {
        /* Return anchor color for invalid index */
        return j->config.anchors[0];
    }
    
    /* Check cache */
    if (index < j->discrete_cache_size) {
        return j->discrete_cache[index];
    }
    
    /* Expand cache if needed */
    if (index >= j->discrete_cache_capacity) {
        int new_capacity = (index + 1) * 2;  /* Grow geometrically */
        CJ_RGB* new_cache = (CJ_RGB*)realloc(j->discrete_cache, 
                                             new_capacity * sizeof(CJ_RGB));
        if (!new_cache) {
            /* Fallback: compute without caching */
            return compute_discrete_color_at_index(j, index);
        }
        j->discrete_cache = new_cache;
        j->discrete_cache_capacity = new_capacity;
    }
    
    /* Fill cache up to requested index */
    for (int i = j->discrete_cache_size; i <= index; i++) {
        j->discrete_cache[i] = compute_discrete_color_at_index(j, i);
    }
    
    j->discrete_cache_size = index + 1;
    
    return j->discrete_cache[index];
}

static CJ_RGB compute_discrete_color_at_index(CJ_Journey_Impl* j, int index) {
    /* Calculate position based on index */
    float t = discrete_position(index);
    
    /* Sample journey at this position */
    CJ_LCh lch = interpolate_waypoints(j, t);
    lch = apply_dynamics(j, lch, t);
    
    /* Apply contrast enforcement if this is sequential */
    if (index > 0 && index - 1 < j->discrete_cache_size) {
        CJ_RGB prev_rgb = j->discrete_cache[index - 1];
        CJ_Lab prev_lab = cj_rgb_to_oklab(prev_rgb);
        CJ_Lab this_lab = cj_lch_to_oklab(lch);
        
        float min_de = get_contrast_threshold(&j->config);
        this_lab = cj_enforce_contrast(this_lab, prev_lab, min_de);
        lch = cj_oklab_to_lch(this_lab);
    }
    
    /* Apply variation if enabled */
    if (j->config.variation_enabled) {
        lch = apply_variation(j, lch, index);
    }
    
    /* Convert back to RGB */
    CJ_Lab lab = cj_lch_to_oklab(lch);
    CJ_RGB rgb = cj_oklab_to_rgb(lab);
    
    return cj_rgb_clamp(rgb);
}
```

#### Memory Management

- Cache grows geometrically (doubles capacity) to amortize allocation cost
- Cache is freed when journey is destroyed
- Maximum practical cache size: ~10KB for 1000 colors (12 bytes × 1000)
- No cache clearing mechanism needed (journey lifecycle is short-lived)

#### Thread Safety

**C API:** Not thread-safe due to internal caching. Document that journey should not be accessed concurrently from multiple threads without external synchronization.

**Swift API:** Same thread-safety constraints. Consider adding a `@MainActor` annotation for SwiftUI use:

```swift
@MainActor
class ColorJourney {
    // ...
}
```

---

## Usage Patterns

### Pattern 1: Progressive UI Building

```swift
class TimelineController {
    let journey: ColorJourney
    var tracks: [Track] = []
    
    init(baseColor: ColorJourneyRGB) {
        self.journey = ColorJourney(
            config: .singleAnchor(baseColor, style: .balanced)
        )
    }
    
    func addTrack(name: String) {
        let trackIndex = tracks.count
        let trackColor = journey[trackIndex]  // Get next color
        
        let track = Track(name: name, color: trackColor)
        tracks.append(track)
    }
    
    func removeTrack(at index: Int) {
        tracks.remove(at: index)
        // No need to regenerate colors - they're deterministic
    }
}
```

### Pattern 2: Tag System

```swift
class TagManager {
    let journey: ColorJourney
    var tags: [String: (index: Int, color: ColorJourneyRGB)] = [:]
    private var nextIndex = 0
    
    init() {
        self.journey = ColorJourney(
            config: .singleAnchor(
                ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.9),
                style: .vividLoop
            )
        )
    }
    
    func addTag(_ name: String) {
        guard tags[name] == nil else { return }
        
        let color = journey[nextIndex]
        tags[name] = (index: nextIndex, color: color)
        nextIndex += 1
    }
    
    func colorForTag(_ name: String) -> ColorJourneyRGB? {
        return tags[name]?.color
    }
}
```

### Pattern 3: Responsive Layout

```swift
class DashboardView {
    let journey: ColorJourney
    
    func updateLayout(columns: Int) {
        // Get exactly the number of colors needed for current layout
        let colors = journey.discrete(range: 0..<columns)
        
        // Apply to UI
        for (index, color) in colors.enumerated() {
            columnViews[index].backgroundColor = color.color
        }
    }
}
```

### Pattern 4: Batch Pre-generation (when count is known)

```swift
class CategorySystem {
    let journey: ColorJourney
    
    func initializeCategories() {
        // Known fixed set - use batch API
        let categoryColors = journey.discrete(count: 8)
        
        for (index, category) in categories.enumerated() {
            category.color = categoryColors[index]
        }
    }
}
```

### Pattern 5: Functional Patterns

```swift
// Get first N colors that meet criteria
let brightColors = journey.discreteColors
    .prefix(100)
    .filter { $0.perceivedBrightness > 0.7 }
    .prefix(10)

// Map to SwiftUI Colors
let uiColors = journey.discreteColors
    .prefix(5)
    .map { $0.color }
```

---

## Performance Considerations

### Memory Usage

**Cache Size:**
- Each `CJ_RGB` = 12 bytes (3 floats)
- 100 colors = 1.2 KB
- 1000 colors = 12 KB
- 10000 colors = 120 KB

**Recommendation:** For most UI use cases (< 100 colors), memory overhead is negligible.

### Computation Cost

**First Access:** ~0.6μs per color (same as current `discrete()`)

**Cached Access:** ~0.05μs (simple array lookup)

**Cache Miss Pattern:**
- Accessing index 0: Computes 1 color
- Accessing index 5: Computes 6 colors (0-5)
- Accessing index 50: Computes 51 colors (0-50)

**Optimal Usage:** Access colors in ascending order for best cache efficiency.

**Worst Case:** Random access pattern (e.g., [50, 2, 99, 10]) pays full computation cost plus cache overhead.

### Recommendations

1. **Sequential Access:** Best performance - each color computed once
2. **Batch Known Counts:** Use `discrete(count:)` when total is known upfront
3. **Range Access:** Use `discrete(range:)` for sequential batches
4. **Random Access:** Acceptable but slightly slower - cache mitigates

---

## Migration Guide

### For C Users

**Before (batch only):**
```c
CJ_RGB palette[10];
cj_journey_discrete(journey, 10, palette);
```

**After (incremental):**
```c
// Option 1: Index access
for (int i = 0; i < track_count; i++) {
    CJ_RGB color = cj_journey_discrete_at(journey, i);
    assign_color(i, color);
}

// Option 2: Range access
CJ_RGB colors[5];
cj_journey_discrete_range(journey, 0, 5, colors);

// Option 3: Still use batch when count is known
CJ_RGB palette[10];
cj_journey_discrete(journey, 10, palette);
```

### For Swift Users

**Before:**
```swift
let colors = journey.discrete(count: trackCount)
for (index, track) in tracks.enumerated() {
    track.color = colors[index]
}
```

**After:**
```swift
// Option 1: Direct subscript
for (index, track) in tracks.enumerated() {
    track.color = journey[index]
}

// Option 2: Functional style
let colors = journey.discreteColors.prefix(trackCount)
zip(tracks, colors).forEach { $0.color = $1 }

// Option 3: Still use batch when count is known
let colors = journey.discrete(count: 10)
```

---

## Testing Strategy

### Unit Tests (C)

```c
void test_discrete_at_consistency() {
    CJ_Config config;
    cj_config_init(&config);
    config.anchors[0] = (CJ_RGB){0.5, 0.5, 0.5};
    config.anchor_count = 1;
    
    CJ_Journey journey = cj_journey_create(&config);
    
    /* Test: Same index returns same color */
    CJ_RGB color1 = cj_journey_discrete_at(journey, 5);
    CJ_RGB color2 = cj_journey_discrete_at(journey, 5);
    assert_rgb_equal(color1, color2, 0.001);
    
    /* Test: Different indices return different colors */
    CJ_RGB color3 = cj_journey_discrete_at(journey, 0);
    CJ_RGB color4 = cj_journey_discrete_at(journey, 10);
    assert_rgb_not_equal(color3, color4, 0.01);
    
    cj_journey_destroy(journey);
}

void test_discrete_range() {
    CJ_Journey journey = create_test_journey();
    
    CJ_RGB range_colors[5];
    cj_journey_discrete_range(journey, 2, 5, range_colors);
    
    /* Verify range matches individual access */
    for (int i = 0; i < 5; i++) {
        CJ_RGB individual = cj_journey_discrete_at(journey, 2 + i);
        assert_rgb_equal(range_colors[i], individual, 0.001);
    }
    
    cj_journey_destroy(journey);
}

void test_cache_efficiency() {
    CJ_Journey journey = create_test_journey();
    
    /* Fill cache */
    for (int i = 0; i < 100; i++) {
        cj_journey_discrete_at(journey, i);
    }
    
    /* Time cached access */
    clock_t start = clock();
    for (int i = 0; i < 100; i++) {
        cj_journey_discrete_at(journey, i);
    }
    clock_t end = clock();
    
    double cached_time = (double)(end - start) / CLOCKS_PER_SEC;
    assert(cached_time < 0.001);  /* Should be very fast */
    
    cj_journey_destroy(journey);
}
```

### Unit Tests (Swift)

```swift
func testDiscreteAtConsistency() {
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5),
            style: .balanced
        )
    )
    
    // Same index returns same color
    let color1 = journey.discrete(at: 5)
    let color2 = journey.discrete(at: 5)
    XCTAssertEqual(color1, color2, accuracy: 0.001)
    
    // Different indices return different colors
    let color3 = journey.discrete(at: 0)
    let color4 = journey.discrete(at: 10)
    XCTAssertNotEqual(color3, color4, accuracy: 0.01)
}

func testSubscriptAccess() {
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8),
            style: .balanced
        )
    )
    
    // Subscript matches discrete(at:)
    XCTAssertEqual(journey[5], journey.discrete(at: 5))
    XCTAssertEqual(journey[0], journey.discrete(at: 0))
}

func testDiscreteRange() {
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.4, g: 0.6, b: 0.7),
            style: .balanced
        )
    )
    
    let rangeColors = journey.discrete(range: 2..<7)
    
    // Verify range matches individual access
    for (offset, color) in rangeColors.enumerated() {
        XCTAssertEqual(color, journey[2 + offset])
    }
}

func testLazySequence() {
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.9),
            style: .vividLoop
        )
    )
    
    // Take first 10
    let first10 = Array(journey.discreteColors.prefix(10))
    XCTAssertEqual(first10.count, 10)
    
    // Verify matches indexed access
    for (index, color) in first10.enumerated() {
        XCTAssertEqual(color, journey[index])
    }
}

func testBackwardCompatibility() {
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.3, g: 0.7, b: 0.5),
            style: .balanced
        )
    )
    
    // Existing batch API still works
    let batchColors = journey.discrete(count: 10)
    XCTAssertEqual(batchColors.count, 10)
    
    // Colors should be distinct
    for i in 0..<9 {
        XCTAssertNotEqual(batchColors[i], batchColors[i + 1], accuracy: 0.05)
    }
}
```

---

## Documentation Requirements

### C Header Documentation

Add comprehensive header documentation:

```c
/**
 * @section Discrete Color Generation
 * 
 * ColorJourney supports three modes of discrete color generation:
 * 
 * 1. **Index-based access** - Get individual colors by index
 *    - cj_journey_discrete_at() - Single color at index
 *    - cj_journey_discrete_range() - Range of colors
 * 
 * 2. **Batch generation** - Generate all colors at once
 *    - cj_journey_discrete() - When total count is known upfront
 * 
 * Index-based access is ideal when:
 * - Adding colors incrementally (UI elements added over time)
 * - Total count is unknown in advance
 * - Random access to specific indices is needed
 * 
 * Batch generation is ideal when:
 * - Total count is known upfront
 * - All colors needed simultaneously
 * - Maximum performance is required
 * 
 * Both modes produce identical colors - discrete(at: N) matches
 * the Nth color from discrete(count: M) where M > N.
 * 
 * @note Colors are cached internally for performance. Accessing
 *       colors in ascending order is most efficient.
 * 
 * @warning Journey handles are not thread-safe. Use external
 *          synchronization if accessing from multiple threads.
 */
```

### Swift Documentation

Add usage guides to README.md:

```markdown
## Incremental Color Generation

When you don't know how many colors you'll need upfront, use index-based access:

### Basic Usage

```swift
let journey = ColorJourney(
    config: .singleAnchor(baseColor, style: .balanced)
)

// Get colors one at a time
let color0 = journey[0]
let color1 = journey[1]
let color5 = journey[5]

// Or use discrete(at:)
let color = journey.discrete(at: 10)
```

### Common Patterns

**Progressive UI Building:**
```swift
class TrackManager {
    let journey: ColorJourney
    
    func addTrack() {
        let index = tracks.count
        let color = journey[index]
        tracks.append(Track(color: color))
    }
}
```

**Functional Style:**
```swift
// Take first N colors that meet criteria
let colors = journey.discreteColors
    .prefix(100)
    .filter { $0.perceivedBrightness > 0.6 }
    .prefix(10)
```

### Performance Tips

- Access colors in ascending order for best cache efficiency
- Use `discrete(count:)` when total count is known upfront
- Use `discrete(range:)` for sequential batches
```

---

## Future Enhancements

### Potential Future Features (Out of Scope for Initial Implementation)

1. **Bidirectional Iteration**
   - Iterator that can move forward/backward
   - Useful for undo/redo scenarios

2. **Sparse Access Optimization**
   - Optimize for random access patterns
   - Compute individual colors without filling cache

3. **Cache Size Limits**
   - Configurable maximum cache size
   - LRU eviction for large indices

4. **Persistent Color Mapping**
   - Save/load color assignments
   - Serialize journey + indices for cross-session consistency

5. **Multi-Journey Coordination**
   - Generate colors from multiple journeys
   - Round-robin or interleaved patterns

---

## Open Questions

### Q1: Should we support negative indices?

**Option A:** Reject negative indices (return error or anchor color)
**Option B:** Support negative indices as wrap-around (Python-style)

**Recommendation:** Option A - keep it simple, no negative indices

### Q2: Should there be a maximum index?

**Option A:** No maximum - unlimited indices (wrapping internally)
**Option B:** Define a maximum (e.g., 10000) and reject beyond

**Recommendation:** Option A - unlimited with wrapping for simplicity

### Q3: How should index-based colors relate to batch-generated colors?

**Requirement:** `journey[i]` should equal `journey.discrete(count: N)[i]` when `i < N`

**Challenge:** Batch generation uses `t = i / (N-1)` while index-based needs a different formula

**Options:**
- **Option A:** Different spacing - accept that they differ
- **Option B:** Make them identical by assuming a canonical total count
- **Option C:** Add configuration to specify "assumed maximum"

**Recommendation:** Option B with documented canonical count (e.g., 100 or 1000)

### Q4: Should cache be clearable?

**Use Case:** Memory-constrained environments

**API:**
```c
void cj_journey_clear_cache(CJ_Journey journey);
```

**Recommendation:** Add if needed, but defer until proven necessary

---

## Conclusion

This specification defines a comprehensive approach to incremental color swatch generation that:

✅ Maintains simplicity for API users  
✅ Ensures perfect consistency (same index → same color)  
✅ Provides excellent performance through internal caching  
✅ Preserves backward compatibility with existing API  
✅ Works naturally in both C and Swift  
✅ Supports multiple access patterns (index, range, sequence, batch)  

The recommended hybrid approach (stateless index access + optional iterator) provides the best balance of simplicity, performance, and flexibility.

### Next Steps

1. **Review & Feedback** - Gather stakeholder input on this specification
2. **Prototype** - Implement proof-of-concept for validation
3. **Testing** - Validate performance and consistency assumptions
4. **Documentation** - Update API docs and usage guides
5. **Implementation** - Full implementation in C core + Swift wrapper
6. **Release** - Ship as minor version update (backward compatible)

---

**Document Status:** ✅ Draft Complete - Ready for Review  
**Estimated Implementation Effort:** 2-3 days (C core + Swift wrapper + tests)  
**API Stability:** Backward compatible - no breaking changes
