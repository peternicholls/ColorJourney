# Quickstart: Using Documented ColorJourney APIs

**Date**: 2025-12-07  
**Feature**: 001-comprehensive-documentation  
**Audience**: New developers, API users, contributors

---

## Quick Navigation

**I'm new to ColorJourney:**
→ Start with [Getting Started](#getting-started)

**I want to generate a color palette:**
→ Jump to [C Core Usage](#c-core-usage) or [Swift Usage](#swift-usage)

**I'm contributing code:**
→ See [Documentation Standards](#documentation-standards)

**I need API reference:**
→ See [Generated Documentation](#generated-documentation)

---

## Getting Started

### What is ColorJourney?

ColorJourney is a deterministic color palette generation library. It creates perceptually uniform color journeys based on anchor colors and high-level configuration (lightness, chroma, contrast, temperature, vibrancy).

**Key features:**
- **Deterministic**: Same config → same colors, always
- **Perceptually sound**: Uses OKLab color space internally
- **Designer-friendly**: Configuration uses perception, not math
- **Portable**: C99 core runs anywhere; Swift wrapper for Apple platforms
- **Performant**: < 1μs per color sample; zero allocations for continuous sampling

### Two-Layer Architecture

```
┌─────────────────────────────────┐
│   Swift Wrapper API             │
│   (Sources/ColorJourney/*.swift)│
│   ↓ Easy to use, type-safe      │
├─────────────────────────────────┤
│   C Core Implementation         │
│   (Sources/CColorJourney/*.c)   │
│   ↓ Portable, zero deps         │
├─────────────────────────────────┤
│   All Platforms                 │
│   (macOS, iOS, Linux, Windows)  │
└─────────────────────────────────┘
```

---

## C Core Usage

### Basic Example: Single-Anchor Journey

```c
#include "ColorJourney.h"
#include <stdio.h>

int main(void) {
    // Create a configuration with one anchor color (red)
    CJ_Config config = {
        .anchors = {{1.0f, 0.0f, 0.0f}},  // sRGB red
        .anchor_count = 1,
        .lightness_bias = 0,      // No adjustment
        .chroma_bias = 0,
        .contrast_bias = 0,
        .temperature_bias = 0,
        .vibrancy_bias = 0,
        .loop_mode = CJ_LOOP_OPEN
    };
    
    // Create a journey from the config
    CJ_Journey* journey = cj_journey_create(&config);
    
    // Sample 5 colors across the journey [0.0, 1.0]
    for (int i = 0; i < 5; ++i) {
        float t = (float)i / 4.0f;  // t ∈ [0, 1]
        CJ_RGB color = cj_sample(journey, t);
        printf("Color %d: RGB(%.2f, %.2f, %.2f)\n", 
               i, color.r, color.g, color.b);
    }
    
    // Clean up
    cj_journey_destroy(journey);
    return 0;
}
```

**Compile and run:**
```bash
gcc -std=c99 -o example main.c Sources/CColorJourney/ColorJourney.c -lm
./example
```

### Multi-Anchor Journey with Biases

```c
// Create a journey from blue to orange, then lighter and more vivid
CJ_Config config = {
    .anchors = {
        {0.0f, 0.0f, 1.0f},    // Blue
        {1.0f, 0.5f, 0.0f}     // Orange
    },
    .anchor_count = 2,
    .lightness_bias = 20,      // Make colors lighter
    .chroma_bias = 30,         // Make colors more vivid
    .contrast_bias = 10,       // Slightly enhance contrast
    .temperature_bias = 0,
    .vibrancy_bias = 0,
    .loop_mode = CJ_LOOP_OPEN
};

CJ_Journey* journey = cj_journey_create(&config);

// Generate a discrete palette of 8 colors
CJ_RGB colors[8];
size_t actual = cj_discrete(journey, 8, colors);
printf("Generated %zu colors\n", actual);

cj_journey_destroy(journey);
```

### Documentation for C Core Functions

**For detailed documentation of each function:**

1. **Read the header file** → `Sources/CColorJourney/include/ColorJourney.h`
   - All public functions are documented with parameters, return values, and examples
   
2. **See generated Doxygen docs** (if available)
   ```bash
   doxygen Doxyfile
   open html/index.html
   ```

3. **Read inline comments** in `Sources/CColorJourney/ColorJourney.c`
   - Algorithm explanations and performance notes

---

## Swift Usage

### Basic Example: Single-Anchor Journey

```swift
import ColorJourney

// Create a configuration with one anchor
let config = ColorJourney.Config(
    anchors: [.init(red: 1.0, green: 0.0, blue: 0.0)],  // Red
    lightnessBias: 0,
    chromaBias: 0,
    contrastBias: 0,
    temperatureBias: 0,
    vibrancyBias: 0,
    loopMode: .open
)

// Create a journey
let journey = ColorJourney(config: config)

// Sample 5 colors
for i in 0..<5 {
    let t = Float(i) / 4.0
    let color = journey.sample(at: t)
    print("Color \(i): RGB(\(color.red), \(color.green), \(color.blue))")
}
```

### Multi-Anchor with Perceptual Biases

```swift
let config = ColorJourney.Config(
    anchors: [
        .init(red: 0.0, green: 0.0, blue: 1.0),  // Blue
        .init(red: 1.0, green: 0.5, blue: 0.0)   // Orange
    ],
    lightnessBias: 20,     // Lighter
    chromaBias: 30,        // More vivid
    contrastBias: 10,      // Better separation
    temperatureBias: 0,
    vibrancyBias: 0,
    loopMode: .open
)

let journey = ColorJourney(config: config)

// Generate a discrete palette
let palette = journey.discrete(count: 8)
print("Generated \(palette.count) colors")
```

### Accessing Perceptual Biases via Enums

```swift
// Use high-level enums for common configurations
let mutedBlues = ColorJourney.Config(
    anchors: [...],
    chromaBias: -50      // Muted (low saturation)
)

let warmPalette = ColorJourney.Config(
    anchors: [...],
    temperatureBias: 40  // Warm (toward red/yellow)
)

let vibrантConfig = ColorJourney.Config(
    anchors: [...],
    vibrancyBias: 50     // Enhanced vibrancy
)
```

### Documentation for Swift API

**For detailed documentation:**

1. **Use Xcode Quick Help** → Hover over any type or function
   - Full description, parameters, examples
   
2. **Read inline DocC comments** in `Sources/ColorJourney/ColorJourney.swift`
   - Perceptual explanations and usage patterns
   
3. **Generate DocC documentation** (if configured)
   ```bash
   swift package generate-documentation
   ```

---

## Documentation Standards

### Writing Documented Code

**For C functions:**
```c
/**
 * @brief Brief description of what the function does
 * 
 * Longer description explaining purpose, algorithm, and important notes.
 * 
 * @param param1 Description and valid range
 * @param param2 Description and valid range
 * @return Description of return value and what it means
 * @pre Precondition (e.g., param1 must be initialized)
 * @post Postcondition (e.g., return value in range [0, 1])
 * @note Performance characteristics or important caveats
 */
```

**For Swift types/functions:**
```swift
/// Brief one-line summary.
///
/// Longer description explaining purpose and behavior.
///
/// - Parameters:
///   - param1: Description and valid values
///   - param2: Description and valid values
/// - Returns: Description of return value
/// - Example:
///   ```swift
///   let result = function(param1: value, param2: value)
///   ```
public func function(param1: Type, param2: Type) -> ReturnType {
```

### Test Documentation

```c
// Test Case: [What is being tested]
// Why this matters: [Why this test is important]
// Expected: [Expected behavior]
void test_something_meaningful(void) {
    // Setup: Create necessary objects
    
    // Execute: Perform the operation
    
    // Verify: Check results
    assert(condition);
}
```

### Commenting Best Practices

- **Explain "why"**, not "what" – Code shows what it does; comments explain why
- **Use proper terminology** – Consistent with Constitution, PRD, and other docs
- **Reference external docs** – Link to Constitution, PRD, performance analysis when relevant
- **Keep comments in sync** – Update comments when code changes
- **Examples > explanations** – Show, don't tell; include runnable examples

---

## Generated Documentation

### Doxygen (C API)

Generate C API reference from Doxygen comments:
```bash
cd /path/to/ColorJourney
doxygen Doxyfile
open html/index.html
```

**Location**: `Sources/CColorJourney/ColorJourney.h` and `.c`

### DocC (Swift API)

Generate Swift documentation:
```bash
swift package generate-documentation --hosting-base-path ColorJourney
```

**Location**: `Sources/ColorJourney/ColorJourney.swift`

### Documentation Standards File

See `DOCUMENTATION.md` in the repository root for:
- Style guide and conventions
- Tools and how to use them
- Maintenance procedures
- Terminology glossary

---

## Common Questions

**Q: How do I know which anchor colors to use?**  
A: Anchor colors are your starting points. Start with 2-3 colors you like visually. The perceptual biases (lightness, chroma, contrast, temperature, vibrancy) then refine the journey between them. See `Examples/` for common patterns.

**Q: What does "deterministic" mean?**  
A: Same configuration always produces the same colors. You can bake a palette config into your design system and use it everywhere. No surprises.

**Q: Can I use variation for organic-looking palettes?**  
A: Yes, but it's disabled by default. Enable it with `variation_config.enabled = true` and a seed. Variation is also deterministic: same seed = same variation.

**Q: How do I contribute documentation?**  
A: Follow the standards in `DOCUMENTATION.md`. Update code comments, verify examples compile, and ensure terminology is consistent.

**Q: Where's the full API reference?**  
A: See the generated Doxygen (C) or DocC (Swift) documentation, or read the header/Swift files directly. Both have complete function documentation.

---

## Next Steps

1. **Explore examples** → `Examples/` directory
2. **Read the specification** → `specs/001-comprehensive-documentation/spec.md`
3. **Review the Constitution** → `.specify/memory/constitution.md`
4. **Understand the architecture** → See code comments in `Sources/`
5. **Check performance** → See `DevDocs/stress-test/`

---

**Last Updated**: 2025-12-07
