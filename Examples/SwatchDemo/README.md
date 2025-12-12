# Incremental Swatch Demo

A practical CLI demonstration of ColorJourney's **palette engine** incremental access patterns.

## What is the Palette Engine?

The **palette engine** is ColorJourney's system for generating discrete color swatches with guaranteed perceptual contrast. Unlike traditional color libraries that require you to specify exactly how many colors you need upfront, the palette engine supports dynamic, incremental access.

## Running the Demo

### Build and Run

```bash
cd /path/to/ColorJourney
swift build -c release
./.build/release/swatch-demo
```

Or use Swift Package Manager directly:

```bash
swift run swatch-demo
```

## What It Demonstrates

### Demo 1: Progressive UI Building
Shows how applications add UI elements one at a time (like timeline tracks) and get colors on-demand without knowing the final count.

**Access Pattern:** Subscript `journey[index]`

### Demo 2: Tag System
Demonstrates a mixed access pattern where initial elements are batched and new elements are added incrementally.

**Access Patterns:** Range `journey.discrete(range:)` + Index `journey[index]`

### Demo 3: Responsive Layout
Shows how the lazy sequence adapts to dynamic column counts as the screen resizes.

**Access Pattern:** Lazy Sequence `journey.discreteColors.prefix(n)`

### Demo 4: Data Visualization
Demonstrates batch access for charts with varying category counts.

**Access Pattern:** Range `journey.discrete(range:)`

### Demo 5: Access Pattern Comparison
Proves that all four access methods produce identical colors, so you can choose based on readability.

**Access Patterns:**
- Subscript: `journey[i]`
- Index: `journey.discrete(at: i)`
- Range: `journey.discrete(range: start..<end)`
- Lazy: `journey.discreteColors.prefix(n)`

### Demo 6: Style Showcase
Displays all 6 pre-configured journey styles for different aesthetic goals.

## Access Patterns Explained

| Pattern | Use Case | Example |
|---------|----------|---------|
| **Single Index** `journey[i]` | Adding elements one at a time | Timeline tracks, tags, progressive UI |
| **Index Method** `journey.discrete(at: i)` | Explicit index access | Same as above, more verbose |
| **Range** `journey.discrete(range: start..<end)` | Batch of sequential colors | Charts, grids, known count |
| **Lazy Sequence** `journey.discreteColors.prefix(n)` | Dynamic count, streaming | Responsive layouts, progressive loading |
| **Batch** `journey.discrete(count: n)` | All colors upfront | Pre-computing entire palette |

## Key Properties

✅ **Deterministic** - Same inputs always produce identical outputs  
✅ **Perceptually Distinct** - Enforced minimum contrast (OKLab ΔE)  
✅ **Portable** - C99 core + Swift wrapper  
✅ **Real-time** - Optimized for fast color generation  
✅ **No Caching Needed** - Each color can be accessed independently  

## Output

The demo generates ANSI-colored terminal output showing:
- Color swatches (█ blocks in actual colors)
- RGB values
- Meta information about access patterns
- Verification that all patterns produce identical results

Example output:
```
████  RGB(0.30, 0.50, 0.80)
████  RGB(0.17, 0.32, 0.68)
████  RGB(0.42, 0.57, 1.00)
```

## Architecture

The demo is implemented as an executable target in the ColorJourney package:

```swift
// In Package.swift
.executableTarget(
    name: "SwatchDemo",
    dependencies: ["ColorJourney"],
    path: "Examples/SwatchDemo"
)
```

This ensures it:
- Compiles with the full ColorJourney package
- Has access to all APIs
- Demonstrates real-world usage patterns

## Exploring Further

See the [CODE_REVIEW_INCREMENTAL_SWATCH.md](../../CODE_REVIEW_INCREMENTAL_SWATCH.md) for detailed implementation analysis.

Or check the [INCREMENTAL_SWATCH_SPECIFICATION.md](../../DevDocs/INCREMENTAL_SWATCH_SPECIFICATION.md) for the design specification.

## Code Structure

The demo is organized into:
- **Demo Functions** (6 demonstrations)
- **Helper Functions** (color formatting, string utilities)
- **Main Entry** (orchestrates all demos)

Each demo is self-contained and can be easily adapted for your own use cases.

---

**Next Step:** Try modifying one of the demos to match your application's use case!
