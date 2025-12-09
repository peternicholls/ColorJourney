# Documentation Standards & Conventions

**Last Updated**: 2025-12-08  
**Maintainer**: ColorJourney Team  
**Status**: Active

This document defines the documentation standards, conventions, and maintenance procedures for the ColorJourney project. All contributors are expected to follow these guidelines to ensure consistency, clarity, and discoverability across the codebase.

---

## Table of Contents

1. [Overview](#overview)
2. [Terminology Glossary](#terminology-glossary)
3. [Documentation Standards](#documentation-standards)
4. [Comment Templates](#comment-templates)
5. [External References](#external-references)
6. [Review Checklist](#review-checklist)
7. [Maintenance Procedures](#maintenance-procedures)
8. [Tools & Generation](#tools--generation)

---

## Overview

ColorJourney documentation serves five critical audiences:

1. **New Developers** - Getting started, understanding basic API and concepts
2. **C Developers** - Using the core C library via FFI, WASM, or direct compilation
3. **Swift Developers** - Integrating into iOS/macOS applications
4. **Maintainers** - Understanding architecture, design decisions, and constraints
5. **Tool Developers** - Using documentation for API discovery and IDE integration

Our documentation strategy:
- **Inline comments** for *why* (design decisions, perceptual guarantees, constraints)
- **Function/type documentation** for *what* (signatures, parameters, behavior, examples)
- **ARCHITECTURE.md** for *how* (system design, data flow, performance characteristics)
- **README.md** for *getting started* (quick examples, links to deeper docs)
- **Examples/** for *working code* (annotated, runnable, tested)

---

## Terminology Glossary

All documentation must use consistent terminology. This glossary is the single source of truth.

### Core Concepts

**Journey**  
A parametrized path through color space from one or more anchor colors. A journey defines how colors are sampled or generated based on position (parameter t ∈ [0, 1]). Journeys can be open (distinct start/end), closed (loops back), or ping-pong (reverses).

**Anchor Color(s)**  
The starting color(s) that define a journey. Can be single-anchor (one source color) or multi-anchor (multiple waypoints). Anchors are specified in RGB and internally converted to OKLab for processing.

**Sampling / Sample**  
The act of querying a color from a journey at a specific parameter value (t). Continuous sampling returns intermediate colors for gradients. Discrete sampling generates a fixed set of palette colors.

**Palette / Discrete Palette**  
A fixed set of distinct colors generated from a journey (e.g., 8 or 12 colors for UI elements). Discrete generation enforces contrast enforcement to ensure adjacent colors are perceptually distinct.

**OKLab Color Space**  
A perceptually uniform color space developed by Björn Ottosson. ColorJourney uses OKLab internally for all color math. OKLab coordinates are:
- **L** (Lightness): Perceived brightness, range [0, 1]
- **a, b** (Chroma/Hue): Color opponents, allow computation of hue angle and saturation

**Perceptual Distance / ΔE (Delta E)**  
The Euclidean distance in OKLab space. In OKLab, √(ΔL² + Δa² + Δb²) approximates human perception of color difference. ColorJourney uses ΔE thresholds to enforce contrast.

### Configuration Dimensions

**Lightness Bias**  
Controls overall brightness (OKLab L) of the generated palette:
- `.neutral` - Preserve anchor lightness
- `.lighter` - Shift toward brighter colors
- `.darker` - Shift toward darker colors
- `.custom(weight)` - Manual adjustment

**Chroma Bias / Saturation**  
Controls colorfulness (saturation) of the journey:
- `.neutral` - Preserve anchor chroma
- `.muted` - Reduce saturation (0.6x multiplier)
- `.vivid` - Increase saturation (1.4x multiplier)
- `.custom(multiplier)` - Manual multiplier

**Contrast / Contrast Level**  
Enforces minimum perceptual separation (OKLab ΔE) between adjacent colors:
- `.low` - Soft separation (ΔE ≥ 0.05)
- `.medium` - Balanced separation (ΔE ≥ 0.1)
- `.high` - Strong separation (ΔE ≥ 0.15)
- `.custom(threshold)` - Custom ΔE threshold

**Temperature Bias**  
Shifts hue toward warm (red, orange, yellow) or cool (blue, green, purple) regions:
- `.neutral` - No temperature bias
- `.warm` - Emphasize warm hues
- `.cool` - Emphasize cool hues

**Loop Mode**  
Defines how the journey behaves at its boundaries:
- `.open` - Start and end are distinct (0 and 1 are different colors)
- `.closed` - Seamlessly loops (color at t=1 matches t=0)
- `.pingPong` - Reverses at ends (goes 0→1→0)

**Mid-Journey Vibrancy**  
Controls color intensity at the center of the journey. Value ∈ [0, 1]:
- Higher values boost chroma/saturation at t=0.5
- Prevents muddy, desaturated midpoints
- Typical range: [0.0, 0.7]

### Variation Layer

**Variation / Seeded Variation**  
Optional micro-variation applied to discrete colors to add organic feel while remaining deterministic:
- Can vary hue, lightness, chroma independently
- Seeded with xoshiro128+ PRNG for repeatability
- Seed determines variation pattern; same seed = same variation

**Determinism / Deterministic**  
Property of sampling functions: given identical inputs (anchor colors, configuration, seed), output is byte-identical across platforms and runs. All ColorJourney functions are deterministic (no randomness unless seeded variation is enabled).

---

## Documentation Standards

### Scope: What to Document

**ALWAYS document:**
- All public functions, types, structs, enums, and properties
- Function parameters, return values, and error conditions
- Struct/enum field meanings and valid ranges
- Perceptual effects (e.g., how a bias affects output)
- Algorithm rationale (why this approach, trade-offs)
- Memory ownership and lifetime (allocation, deallocation)
- Determinism guarantees or lack thereof
- Cross-platform behavior differences (if any)

**USUALLY document (if non-obvious):**
- Edge cases and boundary behavior
- Performance characteristics
- Design decisions and constraints
- References to external standards (OKLab, Constitution, etc.)
- Examples of usage patterns

**OPTIONALLY document:**
- Internal helper functions (unless they're complex or called from multiple places)
- Obvious implementations (e.g., `return a + b`)

### Location: Where to Document

| What | Where | Format |
|------|-------|--------|
| Public C functions | `Sources/CColorJourney/ColorJourney.h` (declaration) + `.c` (implementation) | Doxygen comments |
| Public C structs/enums | `Sources/CColorJourney/include/ColorJourney.h` | Doxygen + inline field comments |
| Public Swift types/functions | `Sources/ColorJourney/ColorJourney.swift` | DocC comments |
| Algorithms, complex logic | Both header and implementation with `/// ALGORITHM:` block comments | Doxygen/DocC + prose |
| Architecture, design | `ARCHITECTURE.md` | Markdown sections |
| Getting started | `README.md` (Quick Start section) | Markdown |
| Examples | `Examples/CExample.c`, `Examples/SwiftExample.swift` | Inline code comments |
| External references | `DOCUMENTATION.md` (External References section) | Markdown table |

---

## Comment Templates

Use these templates to standardize comment format and ensure consistency.

### C Function Documentation (Doxygen)

```c
/**
 * @brief Brief description of what the function does (< 80 chars).
 *
 * Longer explanation if needed, describing behavior, side effects,
 * and perceptual guarantees. Reference external documents or principles
 * if relevant.
 *
 * @param anchor The anchor color in RGB space [0, 1]
 * @param config Configuration specifying biases and journey parameters
 * @param count Number of discrete colors to generate (≥ 1)
 *
 * @return Array of @c count colors in RGB. Caller must free with free().
 *         Returns NULL if allocation fails.
 *
 * @note This function is deterministic: identical inputs produce identical outputs.
 * @note Algorithm is O(n) where n is @c count; see ALGORITHM section below.
 *
 * ALGORITHM:
 * ------
 * [Explain the algorithm, trade-offs, why this approach.]
 * References: OKLab paper, Constitution Principle II (perceptual), etc.
 */
CJ_RGB* CJ_JourneyDiscrete(CJ_RGB anchor, CJ_Config config, int count);
```

### C Struct Field Documentation

```c
typedef struct {
    float lightness_weight;   ///< Bias toward lighter colors; range [-1, 1]
                              ///< 0 = neutral, > 0 = lighter, < 0 = darker
    float chroma_multiplier;  ///< Saturation multiplier; range [0.5, 2.0]
                              ///< 1.0 = neutral, < 1.0 = muted, > 1.0 = vivid
} CJ_Bias;
```

### Swift Documentation: Swift-DocC

**Reference:** [Swift-DocC Documentation](https://www.swift.org/blog/swift-docc/)

Swift-DocC is the modern documentation format for Swift libraries. It uses triple-slash comments (`///`) and generates interactive documentation with code samples, cross-references, and IDE integration.

#### DocC Comment Structure

```swift
/// One-sentence summary of what this type/function does.
///
/// A longer description that explains the purpose, behavior, and use cases.
/// Can span multiple paragraphs. Use clear, perceptual language.
///
/// ## Topics (optional)
///
/// Organize related functionality into logical groups:
/// - Section Name with list of related items
///
/// ## Examples (recommended)
///
/// Include runnable code examples. Use markdown code blocks with swift syntax:
///
/// ```swift
/// let config = ColorJourneyConfig.singleAnchor(color, style: .balanced)
/// let journey = ColorJourney(config: config)
/// let palette = journey.discrete(count: 8)
/// ```
///
/// ## Perceptual Effects (where applicable)
///
/// Explain what users will *see* and *feel*, not technical details.
///
/// - Parameters:
///   - paramName: Description of what this parameter does, valid range, defaults
///   - otherParam: Clear explanation of purpose and constraints
///
/// - Returns: Description of return value, its type, and what it represents
///
/// - Throws: Describe error cases if this can throw
///
/// - Note: Important caveats or performance implications
///
/// - Attention: Critical information developers must know
///
/// - SeeAlso: ``RelatedType``, ``relatedFunction()`` for related functionality
public func discrete(count: Int) -> [ColorJourneyRGB]
```

#### Complete Example: DocC Function Documentation

```swift
/// Generates a discrete palette of distinct colors sampled from the journey.
///
/// This function samples the journey at evenly-spaced parameters and enforces
/// minimum perceptual contrast (OKLab ΔE) between adjacent colors. This ensures
/// palette colors are visually distinct for UI elements, timeline tracks, or
/// category labels.
///
/// ## Perceptual Guarantees
///
/// - Adjacent colors maintain minimum ΔE per configured contrast level
/// - No colors appear washed out or muddy
/// - Lightness and chroma follow configured biases
///
/// ## Performance
///
/// O(n) time complexity, where n = count. Typical: 100-color palette in < 1ms.
/// No allocations for continuous sampling; ~2KB for discrete palette.
///
/// ## Example
///
/// ```swift
/// let journey = ColorJourney(
///     config: .singleAnchor(
///         ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8),
///         style: .balanced
///     )
/// )
/// let palette = journey.discrete(count: 8)
/// for (i, color) in palette.enumerated() {
///     print("Color \(i): RGB(\(color.red), \(color.green), \(color.blue))")
/// }
/// ```
///
/// - Parameter count: Number of colors to generate (≥ 1). Higher counts sample
///   more densely but preserve perceptual consistency.
///
/// - Returns: Array of `count` distinct `ColorJourneyRGB` colors, ordered by
///   journey parameter from start (0) to end (1).
///
/// - Note: Output is deterministic unless seeded variation is enabled.
/// - Note: Algorithm respects all configured biases (lightness, chroma, temperature, contrast).
///
/// - SeeAlso: ``sample(at:)`` for continuous sampling, ``ContrastLevel`` for contrast configuration
public func discrete(count: Int) -> [ColorJourneyRGB]
```

#### DocC Type Documentation

```swift
/// Represents a color in linear sRGB color space.
///
/// This structure holds color components as floating-point values in the range [0, 1]:
/// - `red`: Red component (0 = no red, 1 = maximum red)
/// - `green`: Green component (0 = no green, 1 = maximum green)
/// - `blue`: Blue component (0 = no blue, 1 = maximum blue)
///
/// ## Platform Conversions
///
/// Convert to platform-specific formats via convenience properties:
/// - `.color` → SwiftUI `Color`
/// - `.uiColor` → UIKit `UIColor` (iOS/iPadOS)
/// - `.nsColor` → AppKit `NSColor` (macOS)
///
/// ## Perceptual Interpretation
///
/// Internally, ColorJourney operates in OKLab perceptual space for all color math.
/// `ColorJourneyRGB` is the public-facing format for input/output, automatically
/// converted to/from OKLab as needed.
///
/// - SeeAlso: [OKLab Color Space](https://bottosson.github.io/posts/oklab/)
public struct ColorJourneyRGB: Hashable {
    public var red: Float
    public var green: Float
    public var blue: Float
}
```

#### DocC Enum Documentation

```swift
/// Enforces minimum perceptual separation between adjacent colors.
///
/// Contrast level ensures generated colors are distinguishable from each other,
/// critical for UIs where colors must be easily read and clicked.
///
/// ## Perceptual Distance (ΔE in OKLab)
///
/// - ΔE ≈ 0.05: Just noticeably different (JND)
/// - ΔE ≈ 0.10: Clearly different, readable at normal viewing
/// - ΔE ≈ 0.15: Distinct, easily distinguishable at a glance
/// - ΔE ≥ 0.20: Very different, bold contrast
///
/// ## Cases
///
/// - `.low`: Soft separation (ΔE ≥ 0.05) for harmonious, subtle palettes
/// - `.medium`: Balanced separation (ΔE ≥ 0.10), recommended for most UIs
/// - `.high`: Strong distinction (ΔE ≥ 0.15) for high accessibility
/// - `.custom(threshold:)`: Custom ΔE threshold
///
/// ## Automatic Adjustment
///
/// If adjacent colors don't meet the threshold, their lightness and chroma
/// are automatically adjusted slightly to ensure distinction while preserving
/// the overall palette character.
public enum ContrastLevel {
    case low
    case medium
    case high
    case custom(threshold: Float)
}
```

#### DocC Best Practices

1. **Use triple-slash `///`** - Enables IDE Quick Help and documentation generation
2. **Write one-sentence summaries** - The first line appears in documentation overview
3. **Explain *what* it feels like** - Use perceptual language ("warm", "vivid", "soft") not technical ("1.4x chroma multiplier")
4. **Include examples** - At least one runnable code sample for each public type/function
5. **Cross-reference related types** - Use `` `` backticks for symbol links (e.g., ``sample(at:)``, ``ContrastLevel``)
6. **Document perceptual effects** - ColorJourney is perceptual; explain the emotional/visual impact
7. **Link to external resources** - OKLab paper, Constitution principles, etc.
8. **Use structured sections** - Parameters, Returns, Throws, Note, Attention, SeeAlso, Topics
9. **Keep examples concise** - 5-15 lines, runnable, showing typical usage

#### Generating DocC Documentation

```bash
# Generate Swift-DocC documentation
swift package generate-documentation

# With custom preview server (optional)
swift package generate-documentation --hosting-base-path "ColorJourney" --output-path ".docs"
```

**Output:** Interactive HTML documentation generated in `.docs/` directory with full cross-reference indexing, search, and IDE integration.

#### IDE Integration

DocC documentation appears automatically in Xcode Quick Help:
- Option+click any symbol → Quick Help panel shows formatted documentation
- Command+click symbol → Jump to definition and full documentation
- Xcode search (Command+Shift+O) → Includes DocC documentation with symbols

This makes your documentation immediately accessible to developers using the library.

### Algorithm Block Comment (Complex Logic)

```c
// ALGORITHM: Fast Cube Root (Newton-Raphson with bit manipulation)
// ===================================================================
// Purpose: Compute x^(1/3) in ~1% error, 3-5x faster than cbrtf().
//
// Trade-off: We trade perfect IEEE 754 compliance for speed.
// This is acceptable because:
// 1. OKLab conversion tolerates ~1% error without visible color difference
// 2. Speed is critical: color generation loops through millions of samples
// 3. Results are consistent across platforms (no IEEE variation)
//
// Method:
// 1. Reinterpret float bits as int for initial guess (clever bit manipulation)
// 2. Use Newton-Raphson iteration: y_new = (2*y + x/(y*y)) / 3
// 3. One iteration gives ~1% error; converges quadratically
//
// Reference: Bit-hack technique from graphics optimization literature.
//            Convergence rate from Newton-Raphson theory.
```

### Design Decision Comment

```swift
// Constitution Principle III (Designer-Centric):
// Defaults favor perceptually pleasing, well-designed output.
// `.balanced` preset provides neutral warmth, medium saturation,
// medium contrast—suitable for most use cases without tuning.
// This reduces cognitive load for developers and ensures good
// results "out of the box."
```

---

## External References

All external references must be accessible and properly cited. This section documents required reading for contributors.

| Reference | Location | Purpose | Access |
|-----------|----------|---------|--------|
| **Constitution** | `.specify/memory/constitution.md` | Core principles: Portability (I), Perceptual Integrity (II), Designer-Centric (III), Determinism (IV), Performance (V) | In repository |
| **PRD** | `DevDocs/PRD.md` | Product requirements, use cases, user stories | In repository |
| **OKLab Paper** | https://bottosson.github.io/posts/oklab/ | Perceptual color space definition, conversion formulas | External (public) |
| **IMPLEMENTATION_STATUS.md** | `DevDocs/IMPLEMENTATION_STATUS.md` | Architecture decisions, current status, known limitations | In repository |
| **API Architecture** | `DevDocs/API_ARCHITECTURE_DIAGRAM.md` | Visual data flow, component relationships | In repository |
| **Stress Test Report** | `DevDocs/stress-test/` | Edge cases, performance analysis, findings | In repository |

When citing these in comments:
- Constitution: `// See Constitution Principle II (Perceptual Integrity) in .specify/memory/constitution.md`
- OKLab: `// OKLab color space (Ottosson): https://bottosson.github.io/posts/oklab/`
- DevDocs: `// See DevDocs/IMPLEMENTATION_STATUS.md for design rationale`

---

## Review Checklist

All documentation (code comments, ARCHITECTURE.md, examples) must pass this review checklist before merge.

### Completeness

- [ ] All public functions/types documented (no missing stubs)
- [ ] All parameters/return values described
- [ ] All enum cases explained with examples
- [ ] All struct fields have ranges or constraints noted
- [ ] Edge cases documented (e.g., what happens if count=0, or color is out of range)
- [ ] Determinism guarantees stated (or noted as non-deterministic)

### Clarity

- [ ] Terminology consistent with [Terminology Glossary](#terminology-glossary)
- [ ] No vague phrases ("handles stuff", "does things")
- [ ] Examples compile and run (tested)
- [ ] Perceptual effects explained (not just technical parameters)
- [ ] Jargon defined or linked to glossary

### References

- [ ] Algorithm comments reference published sources (papers, books, or design docs)
- [ ] Design decisions cite Constitution principles or decision log
- [ ] External links (OKLab, etc.) are valid and permanent
- [ ] Cross-references use proper format (see [External References](#external-references))

### Format

- [ ] C comments use Doxygen format (@param, @return, @brief, etc.)
- [ ] Swift comments use DocC format (/// with structured sections)
- [ ] Code examples are properly formatted and indented
- [ ] No TODO, FIXME, or XXX without issue number or clear owner

---

## Maintenance Procedures

### Adding New Functions or Types

1. **Write documentation FIRST** (before or alongside implementation)
   - Use appropriate template from [Comment Templates](#comment-templates)
   - Fill in all required sections (@brief, @param, @return, etc.)
   - Add examples if applicable

2. **Get review** via pull request
   - Use [Review Checklist](#review-checklist)
   - Reviewers verify completeness, clarity, and format

3. **Update summary sections** (after merge)
   - If API surface expanded, update README.md "Configuration Reference" section
   - If algorithm added, consider updating ARCHITECTURE.md with data flow changes

### Updating Existing Documentation

1. **Keep terminology consistent** - check [Terminology Glossary](#terminology-glossary)
2. **Update cross-references** - if moving docs, update links in README.md, ARCHITECTURE.md, other comments
3. **Verify examples still work** - if changing API, update Examples/ and docstring snippets
4. **Update this file** - if adding new standards or glossary terms

### Periodic Reviews

**Quarterly (or per major release):**
- [ ] Run `make docs` (Doxygen + DocC) and check for warnings
- [ ] Review all examples compile and run
- [ ] Verify external references are still valid
- [ ] Audit for stale TODOs or broken links

**Per PR review:**
- [ ] Contributor uses [Review Checklist](#review-checklist)
- [ ] At least one reviewer checks completeness and clarity

---

## Examples & Validation

All working examples are stored in the `Examples/` directory and must be verified to compile and run.

### Example Requirements (US5)

**File:** `Examples/CExample.c`  
**Purpose:** Demonstrates C API for beginners  
**Verification:** `make verify-example-c`  
- Compiles with gcc -std=c99 without warnings
- Runs and produces expected output
- Includes comments explaining each step
- Demonstrates: journey creation, discrete sampling, continuous sampling, cleanup, seeded variation

**File:** `Examples/SwiftExample.swift`  
**Purpose:** Comprehensive Swift API demonstrations  
**Verification:** `make verify-example-swift`  
- Compiles via `swift build` without errors
- Includes detailed comments for each example section
- Demonstrates: basic journeys, style presets, variation modes, UI use cases, performance

**File:** `Examples/DocstringValidation.swift`  
**Purpose:** Validates all code snippets in doc comments  
**Verification:** `swift build` includes this file  
- 9 separate test functions, each validating a docstring example
- Ensures copy-paste examples from documentation actually compile and work
- Demonstrates common API patterns

### Validating Examples

**Run all verifications:**
```bash
make verify-examples
```

**Run individually:**
```bash
make verify-example-c      # Compile and run C example
make verify-example-swift  # Build Swift examples
```

**Manual validation:**
- Edit a code snippet in an example or docstring
- Rerun `make verify-examples` to ensure it still works
- Update this section if adding new examples

### Adding New Examples

1. **Create file** in `Examples/` with clear name (e.g., `GradientExample.swift`)
2. **Add comprehensive comments** explaining each section
3. **Link example to user story** in opening comment block
4. **Verify it compiles** - run appropriate build command
5. **Add to Makefile** if verification target needed
6. **Reference in README.md** and this section
7. **Get review** - reviewer tests compilation and clarity

---

## Tools & Generation

### C Documentation: Doxygen

**Configuration:** `.specify/doxyfile`

**Generate:**
```bash
doxygen .specify/doxyfile
```

**Output:** HTML documentation in `Docs/doxygen/html/index.html`

**What it parses:**
- All Doxygen comments in `Sources/CColorJourney/include/ColorJourney.h`
- All Doxygen comments in `Sources/CColorJourney/ColorJourney.c`
- Generates cross-references, call graphs, and search index

**Format checklist:**
- Use `@param`, `@return`, `@brief` for signatures
- Use `@note` for important notes
- Use `@see` for cross-references
- Use `///` or `/** */` style (either OK)

### Swift Documentation: Swift-DocC

**Reference:** [Swift-DocC Official Documentation](https://www.swift.org/blog/swift-docc/)

**Configuration:** Embedded in `Package.swift` (Swift 5.9+)

**Generate:**
```bash
# Generate Swift-DocC documentation
swift package generate-documentation

# Generate with custom output path
swift package generate-documentation --output-path .docs

# Generate with hosting configuration for web deployment
swift package generate-documentation \
  --hosting-base-path ColorJourney \
  --output-path .docs
```

**Output:** Interactive HTML documentation in `.build/documentation/` with:
- Searchable documentation for all public types and functions
- Automatic cross-reference resolution
- Syntax highlighting for code examples
- Integrated with Xcode Quick Help (Option+click in Xcode)

**What it parses:**
- All `///` comments in `Sources/ColorJourney/ColorJourney.swift`
- Generates interactive documentation with IDE and web browser viewers
- Automatic symbol indexing for search and navigation

**Format checklist:**

✅ **Comment markers:**
- Use `///` (triple-slash) for documentation comments
- Indent comments to align with code they document

✅ **Structure:**
- First line: One-sentence summary (appears in symbol lists)
- Blank line + longer description (can span multiple paragraphs)
- Structured sections: `- Parameters:`, `- Returns:`, `- Throws:`
- Optional sections: `## Topics`, `## Examples`, etc.
- Cross-references: Use `` ``symbolName`` `` for automatic linking

✅ **Examples:**
- Include at least one runnable example
- Use markdown code blocks with swift language hint
- Keep examples concise (5-15 lines)
- Show typical/recommended usage patterns

✅ **DocC-specific features:**
- `- Parameters:` with parameter name: description format
- `- Returns:` for return value description
- `- Throws:` for error types (if applicable)
- `- Note:` for important caveats
- `- Attention:` for critical information
- `- SeeAlso:` for related symbols using `` `symbolName` ``
- `## Sections` for organizing documentation into Topics

**IDE Integration:**

DocC documentation is automatically available in Xcode:
- **Quick Help (Option+click):** Shows formatted summary and description
- **Quick Help Inspector:** Full documentation in sidebar
- **Jump to Definition (Command+click):** Navigate to symbol definition
- **Documentation Search (Command+Shift+O):** Includes DocC documentation

**Web Publication:**

DocC-generated documentation can be hosted on static web servers:
```bash
# Generate for web hosting at example.com/ColorJourney/
swift package generate-documentation \
  --hosting-base-path ColorJourney \
  --output-path .docs

# Content ready to upload to hosting provider
# All relative links are automatically handled
```

**Format example - Full Symbol:**

```swift
/// Generates a discrete palette of perceptually distinct colors.
///
/// Samples the journey at evenly-spaced parameters and enforces minimum
/// perceptual contrast between adjacent colors, ensuring palette colors are
/// visually distinct for UI elements, labels, or timelines.
///
/// ## Perceptual Guarantees
///
/// - Adjacent colors maintain configured contrast level (ΔE threshold)
/// - All colors honor lightness and chroma biases
/// - Output is deterministic (unless seeded variation enabled)
///
/// ## Performance
///
/// O(n) time complexity where n = count. Typical performance:
/// - 10 colors: < 10μs
/// - 100 colors: < 100μs
/// - 1000 colors: < 1ms
///
/// ## Example
///
/// ```swift
/// let baseColor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
/// let journey = ColorJourney(
///     config: .singleAnchor(baseColor, style: .balanced)
/// )
/// let palette = journey.discrete(count: 8)
/// ```
///
/// - Parameter count: Number of distinct colors to generate (≥ 1)
/// - Returns: Array of `count` perceptually distinct `ColorJourneyRGB` colors
///
/// - Note: Output is deterministic unless seeded variation is configured
/// - Note: Higher `count` values maintain better perceptual distribution
///
/// - SeeAlso: ``sample(at:)`` for continuous color sampling
/// - SeeAlso: ``ContrastLevel`` for perceptual distance configuration
public func discrete(count: Int) -> [ColorJourneyRGB]
```

**Best practices:**

1. **Perceptual language** - Use "vivid", "warm", "soft" not "1.4x multiplier"
2. **Clear examples** - Include a typical usage example for every public function
3. **Explain impacts** - How does this affect the generated colors? What will users see?
4. **Cross-reference** - Link to related types, functions, and enums
5. **Avoid jargon** - Define or link glossary terms (see [Terminology Glossary](#terminology-glossary))
6. **Document constraints** - Parameter ranges, valid values, edge cases
7. **Performance notes** - Add ## Performance section for critical functions
8. **Constitutional grounding** - Reference Constitution principles where applicable

### Verification Script

**Script:** `.specify/scripts/verify-docs.sh`

**Runs:**
- Doxygen build and checks for warnings
- DocC build and checks for warnings
- Validates all public APIs have documentation stubs
- Checks examples compile

**Usage:**
```bash
bash .specify/scripts/verify-docs.sh
```

### Swift Package Multi-Platform Documentation (Swift-DocC Plugin)

For hosting documentation online from a Swift Package, use the **[Swift-DocC Plugin](https://swiftlang.github.io/swift-docc-plugin/)**.

#### Installation

Add to `Package.swift`:

```swift
.package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
```

#### Generate for Local Development

```bash
# Generate documentation for all targets
swift package generate-documentation

# Or specific target
swift package generate-documentation --target ColorJourney

# Output: .build/documentation/ (indexed for Xcode)
```

#### Generate for Static Web Hosting

For hosting on GitHub Pages or other static hosts:

```bash
# Generate without IDE indexing, transformed for static hosting
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path ColorJourney \
  --output-path ./docs
```

**Flags explained:**
- `--allow-writing-to-directory ./docs` - Allow writing outside sandbox
- `--target ColorJourney` - Document the Swift package target
- `--disable-indexing` - Skip IDE index (not needed for web)
- `--transform-for-static-hosting` - Optimize for static hosting (no server routing rules needed)
- `--hosting-base-path ColorJourney` - URL path where docs will be hosted (e.g., `example.com/ColorJourney/`)
- `--output-path ./docs` - Output directory

#### Generate for Root Path Hosting

If hosting at domain root (e.g., `colors.example.com/`):

```bash
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --output-path ./docs
```

(Omit `--hosting-base-path` when hosting at root)

#### GitHub Pages Publishing

To automatically publish docs to GitHub Pages on each release:

```bash
# .github/workflows/publish-docs.yml example
name: Publish Documentation

on:
  release:
    types: [published]

jobs:
  publish-docs:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: swift-actions/setup-swift@v1
        with:
          swift-version: "5.9"
      
      - name: Build documentation
        run: |
          swift package --allow-writing-to-directory ./docs \
            generate-documentation \
            --target ColorJourney \
            --disable-indexing \
            --transform-for-static-hosting \
            --hosting-base-path ColorJourney \
            --output-path ./docs
      
      - name: Upload to GitHub Pages
        uses: actions/upload-pages-artifact@v2
        with:
          path: ./docs
```

#### Multi-Platform Package Documentation

ColorJourney supports multiple platforms (iOS, macOS, watchOS, tvOS, visionOS, Linux). Documentation is generated for the Swift target, which is multi-platform by default.

**Platform availability in docs:**

Swift-DocC automatically generates documentation for all platforms listed in `Package.swift`:

```swift
platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .macCatalyst(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
]
```

Each symbol in generated docs will indicate which platforms it's available on.

**Note:** The C core (`CColorJourney`) is not directly documented in the Swift-DocC output, but its availability is handled via the Swift wrapper. See [Swift Wrapper Documentation](#swift-documentation-swift-docc) for API details.

#### Verifying Documentation Build

```bash
# Test documentation generation with warnings
swift package generate-documentation --target ColorJourney 2>&1 | grep -i warning

# Verify no broken symbol references
swift package generate-documentation --target ColorJourney 2>&1 | grep -i error
```

#### Documentation Catalog

Create `Sources/ColorJourney/ColorJourney.docc/ColorJourney.md` for a landing page:

```markdown
# ``ColorJourney``

Perceptually uniform color journey generation for multi-platform Swift.

## Overview

ColorJourney generates beautiful, programmatic color palettes using perceptually
uniform color math. Perfect for UIs, timelines, visualizations, and design systems.

## Topics

### Essentials

- ``ColorJourney``
- ``ColorJourneyConfig``

### Configuration

- ``LightnessBias``
- ``ChromaBias``
- ``ContrastLevel``
- ``TemperatureBias``

### Sampling

- ``ColorJourneyRGB``
```

#### Best Practices for Package Docs

1. **Use Swift-DocC plugin** for web publishing (official, maintained, reliable)
2. **Include a .docc catalog** with landing page and topic organization
3. **Document all public APIs** (100% coverage target)
4. **Use cross-references** (`` ``SymbolName`` ``) for navigation
5. **Include examples** in function documentation
6. **Test locally** before publishing (`swift package generate-documentation`)
7. **Host on GitHub Pages** or your own static server
8. **Version your docs** alongside releases

---

## Summary

| Aspect | Standard | Tool | Location |
|--------|----------|------|----------|
| C API Comments | Doxygen format (@param, @return, @brief) | Doxygen | `Sources/CColorJourney/` |
| Swift API Comments | DocC format (///, structured sections) | DocC/Swift-DocC Plugin | `Sources/ColorJourney/` |
| Terminology | Consistent glossary | Manual review | This file (Glossary section) |
| Architecture | Data flow, design decisions | Markdown | `ARCHITECTURE.md` |
| Examples | Annotated, runnable | Manual compile test | `Examples/` |
| References | Constitution, PRD, OKLab, DevDocs | Markdown links | This file (References section) |
| Review | Completeness, clarity, format | [Review Checklist](#review-checklist) | PR comments |
| Package Docs | Swift-DocC plugin for hosting | swift-docc-plugin (SPM) | Command line |

---

## Questions?

- **API usage questions:** See README.md Quick Start section or Examples/
- **Architecture questions:** See ARCHITECTURE.md
- **Documentation standards questions:** See this file or [SWIFT_DOCC_GUIDE.md](SWIFT_DOCC_GUIDE.md)
- **Swift-DocC plugin questions:** See [Swift-DocC Plugin Docs](https://swiftlang.github.io/swift-docc-plugin/)
- **Contributing code:** See CONTRIBUTING.md (links to this file)

---

*This document is maintained as part of the ColorJourney project documentation infrastructure. Last reviewed: 2025-12-08.*
