# Documentation Standards & Compliance Contract

**Version**: 1.0.0  
**Date**: 2025-12-07  
**Status**: Formal Specification

This document defines the standards, tools, and procedures for maintaining documentation in ColorJourney.

---

## Documentation Standards

### Style & Tone

**General Principles**:
- **Explain "why," not just "what"** – Code shows what it does; comments explain design decisions and constraints
- **Be precise and concise** – Avoid redundancy; use terminology consistently
- **Use active voice** – "The journey interpolates colors" rather than "Colors are interpolated by the journey"
- **Link to references** – Point to Constitution, PRD, performance docs, and academic papers when relevant
- **Assume competence** – Readers know their primary language (C or Swift); explain color science and algorithms clearly but not condescendingly

**Terminology Requirements**:
- Use the glossary below; enforce consistency
- Avoid synonyms (e.g., "offset" vs. "rotation" for hue adjustment)
- When translating between C and Swift APIs, maintain term consistency
- Document non-obvious abbreviations (e.g., "ΔE" = perceptual color distance)

**Examples**:
- All public APIs MUST include at least one usage example
- Examples must be runnable and verified (see Verification section below)
- Examples should show the most common use case and one advanced case
- Keep examples focused; use comments to explain key steps

---

## C Core Documentation Standards

### Function Documentation (Doxygen Style)

All public functions in `ColorJourney.h` and algorithm implementations in `ColorJourney.c` must use Doxygen JavaDoc comments.

**Template**:
```c
/**
 * @brief One-sentence summary of what the function does.
 * 
 * Longer description explaining:
 * - Purpose and intended use case
 * - Algorithm overview (for non-trivial functions)
 * - How the function interacts with other parts of the system
 * - Any important assumptions or constraints
 * 
 * @param param1 Description of param1, valid ranges, and semantics.
 * @param param2 Description of param2, valid ranges, and semantics.
 * @return Description of return value, what it represents, and possible values.
 * @pre Precondition (e.g., "config must be initialized and valid")
 * @post Postcondition (e.g., "returned color is in valid sRGB range [0, 1]")
 * @note Performance characteristic or important caveat
 * @see Related functions or documents (e.g., cj_journey_create, Constitution)
 * 
 * @par Example:
 * @code
 * CJ_Config config = {...};
 * CJ_Journey* j = cj_journey_create(&config);
 * CJ_RGB color = cj_sample(j, 0.5f);
 * cj_journey_destroy(j);
 * @endcode
 */
```

**Tags Used**:
- `@brief` – One-line summary
- `@param` – Parameter description (name, range, semantics)
- `@return` – Return value description
- `@pre` – Preconditions
- `@post` – Postconditions
- `@note` – Performance, caveats, or important details
- `@see` – Related functions, documents, or external references
- `@par Example:` – Code example with @code/@endcode

**Minimum Requirements**:
- All public function declarations in `.h` file
- Brief, @param, @return for all functions
- Pre/post conditions for functions with contracts
- Example for all non-trivial functions
- See/references for functions related to Constitution or algorithm choices

---

### Struct Documentation (Doxygen Style)

```c
/**
 * @brief High-level purpose of this struct.
 * 
 * Detailed explanation of when and how to use this struct,
 * and how its fields interact.
 */
typedef struct {
    float channel1;    ///< Description, valid range [0, 1], semantics
    float channel2;    ///< Description, valid range, semantics
} CJ_MyStruct;
```

**Requirements**:
- Struct-level documentation explaining purpose and usage
- Inline `///<` comments for each field explaining purpose, valid ranges, and semantics
- Example usage if struct is frequently configured by users

---

### Algorithm Documentation (Block Comments)

Non-trivial algorithms (fast cube root, journey interpolation, contrast enforcement) must have explanatory block comments.

**Template**:
```c
/*
 * ALGORITHM: [Name]
 * 
 * PURPOSE: [What the algorithm does and why]
 * 
 * APPROACH: [High-level overview of the method]
 * 
 * ASSUMPTIONS:
 *   - [Assumption 1, e.g., "Input sRGB values in [0, 1]"]
 *   - [Assumption 2]
 * 
 * TRADE-OFFS: [Performance vs. accuracy, simplicity vs. correctness]
 * 
 * REFERENCES:
 *   - [Paper or document reference if applicable]
 *   - Constitution Section II: Perceptual Integrity (color space choice)
 * 
 * PRECISION: [Error bounds, e.g., "1% error vs. cbrtf()"]
 */
```

**Placement**: At the start of the function or major code block.

**Minimum Requirements**:
- PURPOSE: What and why
- APPROACH: High-level method
- ASSUMPTIONS: What must be true for correctness
- TRADE-OFFS: Any compromises (performance, accuracy, simplicity)
- REFERENCES: Links to papers, Constitution, docs
- PRECISION: Error bounds or accuracy claims (if applicable)

---

## Swift API Documentation Standards

### Type Documentation (DocC Style)

All public types (structs, enums, classes) must have DocC comments.

**Template**:
```swift
/// One-sentence summary of what this type represents or does.
///
/// Longer description explaining:
/// - Purpose and primary use case
/// - How this type fits into the ColorJourney system
/// - Important behavioral guarantees or constraints
/// - Relationship to C core concepts (if applicable)
///
/// - Example:
///   ```swift
///   var config = ColorJourney.Config(
///       anchors: [/* blue, orange */],
///       lightnessBias: 20,      // Lighter colors
///       chromaBias: 30          // More vivid
///   )
///   let journey = ColorJourney(config: config)
///   let color = journey.sample(at: 0.5)
///   ```
///
/// - See Also: RelatedType, relatedFunction(param:)
public struct MyType { ... }
```

**DocC Tags**:
- `/// Brief comment` – One-liner
- `///` – Paragraph separator (blank line in comment)
- `/// - Parameters:` – Parameter documentation
- `/// - Returns:` – Return value documentation
- `/// - Throws:` – Error documentation (if applicable)
- `/// - Example:` – Code example with triple-backtick code block
- `/// - See Also:` – Related types or functions

**Minimum Requirements**:
- Brief one-liner
- Longer description explaining purpose and context
- Parameter documentation for all function parameters
- Return documentation for all non-void functions
- Example showing the most common use case
- Links to related types or functions

---

### Property Documentation (DocC Style)

```swift
/// Perceptual lightness adjustment.
///
/// Adjusts the perceived brightness of all colors in the journey.
/// - Negative values darken colors
/// - Positive values brighten colors
/// - Valid range: [-100, +100]; clamped to range
/// - Default: 0 (no adjustment)
public var lightnessBias: Float = 0
```

**Requirements**:
- Explain perceptual effect, not mathematical implementation
- List valid ranges and what happens outside them
- Explain default value and what it means
- Use consistent terminology (see glossary below)

---

### Enum Case Documentation (DocC Style)

```swift
/// Seamlessly loops back to start.
///
/// The journey wraps at the boundary, maintaining perceptual continuity.
/// Useful for cyclic color schemes like hue wheels.
case closed
```

**Requirements**:
- Explain the perceptual or behavioral effect
- Describe the use case or when to use this case
- Compare with other cases if relevant

---

## Example Code Verification

### Verification Process

All example code (in docs, docstrings, and `Examples/` directory) must:

1. **Compile without warnings**:
   ```bash
   # C examples
   gcc -std=c99 -Wall -Wextra -o example example.c \
       Sources/CColorJourney/ColorJourney.c -lm
   
   # Swift examples
   swift build -c release
   ```

2. **Run without errors**:
   ```bash
   # C example
   ./example
   # (produces output or exits successfully)
   
   # Swift example
   swift run Example
   ```

3. **Produce valid output**:
   - Colors in valid sRGB range (0.0 to 1.0 per channel)
   - No undefined behavior or crashes
   - Output matches expected behavior described in comments

4. **Be self-contained**:
   - No external dependencies beyond ColorJourney and standard libraries
   - No external configuration files or setup required
   - Runnable from command line without modification

### CI/CD Integration

Examples should be verified in CI/CD:
- Compile all C examples with strict flags
- Verify all Swift examples with `swift build`
- Run examples and validate output format
- Fail build if any example fails to compile or run

### Example Structure

```c
/**
 * EXAMPLE: Creating a multi-anchor journey with perceptual biases
 * 
 * This example demonstrates:
 *   - Multi-anchor color path (blue to orange)
 *   - Perceptual biases (lightness, chroma)
 *   - Discrete palette generation with contrast enforcement
 * 
 * Expected output: 8 colors, evenly spaced with enforced contrast
 */
#include "ColorJourney.h"
#include <stdio.h>

int main(void) {
    // Setup: Define anchors
    CJ_Config config = {
        .anchors = {
            {0.0f, 0.0f, 1.0f},  // Blue
            {1.0f, 0.5f, 0.0f}   // Orange
        },
        .anchor_count = 2,
        .lightness_bias = 20,    // Lighter
        .chroma_bias = 30,       // More vivid
        .contrast_bias = 10,     // Enforce contrast
        .loop_mode = CJ_LOOP_OPEN
    };
    
    // Create journey
    CJ_Journey* journey = cj_journey_create(&config);
    
    // Generate palette
    CJ_RGB colors[8];
    size_t count = cj_discrete(journey, 8, colors);
    
    // Output
    printf("Generated %zu colors:\n", count);
    for (size_t i = 0; i < count; ++i) {
        printf("  Color %zu: RGB(%.2f, %.2f, %.2f)\n", 
               i, colors[i].r, colors[i].g, colors[i].b);
    }
    
    // Cleanup
    cj_journey_destroy(journey);
    return 0;
}
```

---

## Terminology Glossary

**Anchor** – A keypoint color in the journey; defines the path that the journey follows.

**Chroma** – Color saturation in OKLab space; higher = more vivid, lower = more grayscale.

**Chroma Bias** – Perceptual adjustment shifting colors toward muted or vivid.

**Chromatic** – Related to chroma/color (not luminance).

**Closed Loop** – Journey mode where the path loops back to start seamlessly.

**Config / Configuration** – High-level parameters defining a journey (anchors, biases, loop mode, variation).

**Contrast** – Perceptual distance between colors; minimum enforced in discrete palettes.

**Contrast Bias** – Adjustment enhancing or reducing perceptual separation between colors.

**Continuous Sampling** – Generating colors at arbitrary points in [0, 1] (infinite colors possible).

**Discrete Palette** – Finite set of colors extracted from a journey (typically 5-20 colors).

**Deterministic** – Property that same input always produces same output, bit-for-bit, on all platforms.

**ΔE (Delta E)** – Perceptual color distance in OKLab space (Euclidean distance in Lab coordinates).

**Designer-Centric** – Configuration using aesthetic intent, not mathematical parameters (per Constitution).

**Journey** – A continuous color path defined by anchors and configuration; can be sampled at any point [0, 1].

**Lightness** – Perceived brightness in OKLab space (L coordinate, 0 = black, 1 = white).

**Lightness Bias** – Perceptual adjustment shifting colors darker or lighter.

**Loop Mode** – Boundary behavior of a journey (open, closed, ping-pong).

**OKLab** – Perceptually uniform color space used internally for all computations (canonical per Constitution).

**Perception / Perceptual** – Related to human color perception, not mathematical representation.

**Ping-Pong** – Journey mode where the path bounces between start and end.

**Precondition** – Requirement that must be true before calling a function.

**Postcondition** – Guarantee that will be true after a function returns.

**sRGB** – Standard RGB color space; input/output format for all APIs.

**Temperature** – Color temperature (cool = blue, warm = red/yellow) in perceptual terms.

**Temperature Bias** – Adjustment shifting colors toward cool or warm.

**Variation** – Optional, deterministic micro-adjustments for organic aesthetics (disabled by default).

**Vibrancy** – Overall color vitality; combination of saturation and contrast.

**Vibrancy Bias** – Adjustment enhancing or reducing overall color vitality.

---

## Documentation Maintenance

### Review Checklist

Before submitting code with documentation:

- [ ] All public APIs have documentation comments (Doxygen for C, DocC for Swift)
- [ ] Documentation explains "why," not just "what"
- [ ] All parameters, return values, and preconditions are documented
- [ ] Examples in documentation are runnable and verified
- [ ] Terminology matches the glossary above
- [ ] References to Constitution, PRD, papers are included (where relevant)
- [ ] No typos or grammatical errors
- [ ] Descriptions are concise and precise

### Maintenance Schedule

- **Documentation generation**: Weekly (Doxygen, DocC builds verified)
- **Example verification**: With each commit (CI/CD checks)
- **Terminology audit**: Quarterly (grep for inconsistencies)
- **Glossary updates**: As new terms are introduced (MINOR version bump)

### Tools & Commands

**Doxygen (C API)**:
```bash
# Generate C API documentation
doxygen Doxyfile

# View generated docs
open html/index.html
```

**DocC (Swift API)**:
```bash
# Build Swift documentation
swift package generate-documentation

# Preview in Xcode
swift package generate-documentation --hosting-base-path ColorJourney
```

**Verification**:
```bash
# Compile all examples
make verify-examples

# Check for documentation gaps
make check-docs

# Verify example code
swift test  # Includes example verification
```

---

## Backward Compatibility

### Documentation Changes

- **Adding documentation** – Always backward compatible (PATCH version)
- **Correcting documentation** – Backward compatible (PATCH version)
- **Clarifying terminology** – Backward compatible if consistent (PATCH version)
- **Removing/changing documentation** – May be breaking if it affects API understanding (MINOR or MAJOR)

### Example & Template Updates

- **New examples** – Backward compatible (MINOR version)
- **Updating examples** – Backward compatible if behavior unchanged (PATCH version)
- **Breaking example changes** – Coordinate with API changes (MINOR/MAJOR version)

---

## Compliance Verification

**Manual Checks**:
- Code review ensures documentation completeness
- Terminology audit (quarterly) checks consistency
- Example verification (continuous) ensures runnable code

**Automated Checks**:
- CI/CD verifies examples compile and run
- Documentation generation tools (Doxygen, DocC) validate comment syntax
- Linters can check for missing documentation (if configured)

---

**Standards Version**: 1.0.0 | **Effective**: 2025-12-07
