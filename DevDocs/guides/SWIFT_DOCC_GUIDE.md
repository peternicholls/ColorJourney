# Swift-DocC Guide for ColorJourney

**Last Updated**: 2025-12-08  
**Reference**: [Swift-DocC Blog](https://www.swift.org/blog/swift-docc/)  
**Scope**: Complete guide to documenting Swift code with Swift-DocC format

This guide explains how to write Swift-DocC documentation for ColorJourney that automatically integrates with Xcode Quick Help, generates searchable web documentation, and provides IDE symbol completion.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [DocC Comment Format](#docc-comment-format)
3. [Symbol Documentation](#symbol-documentation)
4. [Cross-References](#cross-references)
5. [Examples](#examples)
6. [Structured Sections](#structured-sections)
7. [Generating & Viewing](#generating--viewing)
8. [Best Practices for ColorJourney](#best-practices-for-colorjourney)
9. [Troubleshooting](#troubleshooting)

---

## Quick Start

### The Basics

```swift
/// One-line summary of what this does.
///
/// Longer description explaining behavior, use cases, and effects.
/// Can span multiple paragraphs.
///
/// - Parameters:
///   - paramName: Description of this parameter [valid range]
/// - Returns: Description of return value
/// - SeeAlso: ``RelatedType``, ``relatedFunc()``
public func myFunction(paramName: Int) -> String
```

### What Gets Documented

- ✅ Public structs, classes, enums, functions, properties
- ✅ Public initializers
- ✅ Enum cases (can have their own `///` comments)
- ✅ Associated types
- ❌ Private/internal symbols (not public API)
- ❌ Implementation details (use `//` comments instead)

### How Developers See It

**In Xcode:**
1. Option+click on any public symbol → Quick Help panel
2. View formatted summary, parameters, return type, examples
3. Command+click → Jump to definition with full documentation

**In Generated Web Documentation:**
1. Run `swift package generate-documentation`
2. Open `.build/documentation/` in web browser
3. Search for symbols, browse organized topics, view examples

---

## DocC Comment Format

### Comment Markers

Use **triple-slash `///`** for documentation comments:

```swift
/// This is a documentation comment.
/// Multiple lines are supported.
/// All these lines contribute to the documentation.
public func example() {}
```

**Do NOT use** `//` (single-line comments) for documentation:

```swift
// This is a regular comment (not included in documentation)
public func example() {}
```

### Structure

All DocC comments follow this structure:

```swift
/// One-sentence summary.
///
/// Paragraph 1: Longer description explaining purpose, behavior, common use cases.
/// Can span multiple paragraphs for complex concepts.
///
/// Paragraph 2: Additional details, constraints, or perceptual effects.
///
/// ## Topics (optional section)
/// 
/// Detailed explanation, examples, or organized content.
///
/// - Parameters:
///   - paramName: Description [valid range]
/// - Returns: What you get back
/// - SeeAlso: ``RelatedType``, ``relatedFunc()``
public func doSomething(paramName: Type) -> ReturnType
```

### One-Sentence Summary

The **first line** is critical—it appears in symbol lists, Quick Help, and search results:

✅ **Good:**
```swift
/// Generates a palette of distinct colors with enforced perceptual contrast.
```

✅ **Good (technical):**
```swift
/// Creates a discrete set of evenly-sampled journey colors.
```

❌ **Bad (too vague):**
```swift
/// Handles discrete color generation.
```

❌ **Bad (too detailed):**
```swift
/// Samples the journey at evenly-spaced parameters t=0, t=1/n, ..., t=n/(n-1), enforces minimum perceptual ΔE separation via lightness/chroma adjustment.
```

---

## Symbol Documentation

### Struct Documentation

```swift
/// Represents a color in linear sRGB color space.
///
/// Holds three floating-point components (red, green, blue) each in range [0, 1].
/// Values outside [0, 1] represent extended gamut colors (not displayable on most screens).
///
/// ## Converting to Platform Colors
///
/// Use convenience properties to convert to platform-specific types:
/// - `.color` → SwiftUI `Color`
/// - `.uiColor` → UIKit `UIColor` (iOS/iPadOS)
/// - `.nsColor` → AppKit `NSColor` (macOS)
///
/// ## Perceptual Interpretation
///
/// ColorJourney converts sRGB to OKLab internally for perceptually uniform color math.
/// See ``ColorJourneyConfig`` for perceptual adjustment options.
///
/// - SeeAlso: [OKLab Color Space](https://bottosson.github.io/posts/oklab/)
public struct ColorJourneyRGB: Hashable {
    /// Red component [0, 1]
    public var red: Float
    /// Green component [0, 1]
    public var green: Float
    /// Blue component [0, 1]
    public var blue: Float
}
```

### Enum Documentation

```swift
/// Shifts hue toward warm (red, orange, yellow) or cool (blue, cyan, purple) regions.
///
/// Temperature bias rotates hue without changing lightness or saturation.
///
/// ## Perceptual Effect
///
/// - Warm: Welcoming, energetic, comforting emotional tone
/// - Cool: Calm, peaceful, professional emotional tone
/// - Neutral: Preserves original hue (no shift)
///
/// ## Example
///
/// ```swift
/// let config = ColorJourneyConfig(
///     anchors: [baseColor],
///     temperature: .warm  // Creates warm-toned palette
/// )
/// ```
///
/// - SeeAlso: ``LightnessBias``, ``ChromaBias``
public enum TemperatureBias {
    /// No temperature shift; preserves original hue
    case neutral
    /// Shift toward warm colors (red, orange, yellow)
    case warm
    /// Shift toward cool colors (blue, cyan, purple)
    case cool
}
```

### Function Documentation

```swift
/// Samples a single color from the journey at parameter t.
///
/// Returns the color at position t ∈ [0, 1] along the journey. Useful for
/// generating smooth gradients or animated transitions between colors.
///
/// ## Sampling Behavior
///
/// - `t = 0.0`: Color at journey start (typically first anchor)
/// - `t = 0.5`: Color at journey midpoint
/// - `t = 1.0`: Color at journey end (typically last anchor or rotated start)
///
/// Values outside [0, 1] are handled per ``LoopMode``:
/// - `.open`: Clamped to [0, 1]
/// - `.closed`: Wrapped (seamless loop)
/// - `.pingPong`: Reflected (reverses direction)
///
/// ## Performance
///
/// ~0.6 microseconds per sample (M1 hardware).
/// Safe to call thousands of times without performance concerns.
///
/// ## Determinism
///
/// Always returns identical color for identical parameter (unless seeded variation enabled).
/// See ``VariationConfig`` for variation options.
///
/// ## Example
///
/// ```swift
/// let journey = ColorJourney(
///     config: .singleAnchor(baseColor, style: .balanced)
/// )
///
/// // Sample at regular intervals for smooth gradient
/// for i in 0..<20 {
///     let t = Float(i) / 19.0
///     let color = journey.sample(at: t)
///     print("Position \(i): \(color)")
/// }
/// ```
///
/// - Parameter parameterT: Position along journey [0, 1]
///   - Out-of-range values handled per ``LoopMode``
/// - Returns: ``ColorJourneyRGB`` color at parameter t
///
/// - Note: Output is bit-identical for identical parameters (determinism guarantee)
/// - Note: Seeded variation is applied if enabled in configuration
///
/// - SeeAlso: ``discrete(count:)`` for generating fixed palettes
/// - SeeAlso: ``LoopMode`` for boundary behavior
public func sample(at parameterT: Float) -> ColorJourneyRGB
```

### Property Documentation

```swift
public struct ColorJourneyConfig {
    /// Array of anchor colors defining the journey waypoints.
    ///
    /// Single anchor: Hue rotates around anchor while preserving lightness/chroma.
    /// Multi-anchor: Colors interpolate through multiple waypoints.
    ///
    /// Valid range: 1-8 colors. More anchors = more complex journey.
    public var anchors: [ColorJourneyRGB]
}
```

---

## Cross-References

### Symbol Links

Use backtick-enclosed symbol names to create automatic links:

```swift
/// See ``ColorJourneyConfig`` for configuration options.
/// Use ``sample(at:)`` for continuous sampling.
/// Try ``JourneyStyle.balanced`` for a good default.
```

**Syntax:**
- Type: `` ``TypeName`` ``
- Function: `` ``functionName()`` ``
- Function with parameters: `` ``functionName(param1:param2:)`` ``
- Property: `` ``propertyName`` ``
- Enum case: `` ``EnumName.caseName`` ``

### External Links

Use markdown URL syntax for external documentation:

```swift
/// - SeeAlso: [OKLab Color Space](https://bottosson.github.io/posts/oklab/)
/// - SeeAlso: [Apple's Color Best Practices](https://developer.apple.com/design/resources/)
```

### Topic Groups

Organize related symbols with Topic groups (appears in generated docs):

```swift
/// - SeeAlso: ``ColorJourneyRGB``, ``ColorJourneyConfig``, ``JourneyStyle``
/// - SeeAlso: ``sample(at:)``, ``discrete(count:)``
```

---

## Examples

### Including Code Examples

Use markdown code blocks with `swift` language identifier:

```swift
/// ## Example
///
/// ```swift
/// let baseColor = ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)
/// let journey = ColorJourney(
///     config: .singleAnchor(baseColor, style: .balanced)
/// )
/// let palette = journey.discrete(count: 8)
/// ```
```

### Example Requirements

✅ **Must:**
- Be syntactically valid Swift code
- Show typical/recommended usage
- Be concise (5-15 lines preferred)
- Have context (imports, variable setup)

✅ **Should:**
- Compile and run successfully
- Demonstrate the most common use case
- Show return types/results
- Include comments explaining key points

❌ **Avoid:**
- Error handling examples (unless function throws)
- Edge cases (document separately)
- Overly complex setups
- Ambiguous variable names

### Example: Single-Anchor Journey

```swift
/// ## Single-Anchor Example
///
/// Generate a palette from a single base color:
///
/// ```swift
/// let baseColor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
/// let journey = ColorJourney(
///     config: .singleAnchor(baseColor, style: .vividLoop)
/// )
/// let palette = journey.discrete(count: 12)
/// // palette: 12 distinct colors rotating around hue spectrum
/// ```
public static func singleAnchor(...)
```

### Example: Multi-Anchor Journey

```swift
/// ## Multi-Anchor Example
///
/// Interpolate between multiple colors:
///
/// ```swift
/// let red = ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0)
/// let green = ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0)
/// let blue = ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)
///
/// let journey = ColorJourney(
///     config: .multiAnchor([red, green, blue], style: .balanced)
/// )
/// let palette = journey.discrete(count: 15)
/// // palette: 15 colors interpolating red → green → blue
/// ```
public static func multiAnchor(...)
```

---

## Structured Sections

### Parameters

```swift
/// - Parameters:
///   - count: Number of colors to generate (≥ 1)
///   - seed: Optional random seed for reproducible variation
public func discrete(count: Int, seed: UInt64? = nil)
```

### Returns

```swift
/// - Returns: Array of `count` ``ColorJourneyRGB`` colors in journey order
public func discrete(count: Int) -> [ColorJourneyRGB]
```

### Throws

```swift
/// - Throws: ``ColorJourneyError.invalidCount`` if count < 1
public func discrete(count: Int) throws -> [ColorJourneyRGB]
```

### Note (Important but not critical)

```swift
/// - Note: Output is deterministic unless seeded variation is enabled
/// - Note: All colors enforce configured contrast level
```

### Attention (Critical information)

```swift
/// - Attention: Passing count = 0 will result in empty array
/// - Attention: Seeded variation is enabled by default
```

### SeeAlso (Related symbols)

```swift
/// - SeeAlso: ``sample(at:)`` for continuous color sampling
/// - SeeAlso: ``ContrastLevel`` for configuring color separation
```

---

## Generating & Viewing

### Generate Documentation

```bash
# Generate Swift-DocC documentation (local)
swift package generate-documentation

# Output: .build/documentation/
```

### View in Xcode

```bash
# Open generated docs in Xcode's documentation viewer
open .build/documentation
```

Or:
1. In Xcode: Product → Build Documentation (Cmd+Shift+D)
2. Opens documentation viewer with searchable symbols
3. Option+click any symbol in editor shows Quick Help

### View in Web Browser

```bash
# Generate for web hosting
swift package generate-documentation \
  --hosting-base-path ColorJourney \
  --output-path .docs

# Open in browser
open .docs/documentation/colorjourney/index.html
```

### Deploy to Web

```bash
# Generate static HTML suitable for any web host
swift package generate-documentation \
  --hosting-base-path https://example.com/colorjourney \
  --output-path ./docs_output

# Upload docs_output/ to your web server
```

---

## Best Practices for ColorJourney

### 1. Use Perceptual Language

ColorJourney is about **how colors feel**, not technical RGB values.

✅ **Perceptual:**
```swift
/// Creates warm, energetic colors suitable for attention-drawing UI.
```

❌ **Technical:**
```swift
/// Multiplies chroma by 1.4x and shifts hue +17 degrees.
```

### 2. Explain Emotional Impact

Users care about what the palette will look like:

```swift
case .nightMode
/// Dark, subdued colors optimized for dark UIs and reduced eye strain.
```

### 3. Document Perceptual Guarantees

ColorJourney makes mathematical guarantees about perception:

```swift
/// ## Perceptual Guarantees
///
/// - All colors maintain OKLab lightness within configured bias range
/// - Adjacent colors meet minimum ΔE (perceptual distance) threshold
/// - Hue transitions are smooth and natural (no banding)
```

### 4. Reference the Constitution

Principles guide design decisions:

```swift
/// The default style ``.balanced`` embodies Constitution Principle III
/// (Designer-Centric): it provides good output without manual tuning.
```

### 5. Link to OKLab Paper

Explain color math via external reference:

```swift
/// All color math operates in OKLab perceptual space.
/// - SeeAlso: [OKLab Color Space](https://bottosson.github.io/posts/oklab/)
```

### 6. Include Comparative Examples

Show different styles side-by-side:

```swift
/// ## Style Comparisons
///
/// - `.balanced`: Neutral, versatile, safe default
/// - `.pastelDrift`: Soft, sophisticated, light
/// - `.vividLoop`: Saturated, energetic, high-contrast
/// - `.nightMode`: Dark, suitable for dark UIs
///
/// See ``JourneyStyle`` for all available styles.
```

### 7. Document Performance

ColorJourney is optimized; document typical performance:

```swift
/// ## Performance
///
/// - Single sample: ~0.6 μs (M1 hardware)
/// - Discrete palette (100 colors): ~100 μs
/// - Safe to call thousands of times in animations
```

### 8. Explain Determinism

State whether output is reproducible:

```swift
/// - Note: Output is deterministic (identical input = identical output)
/// - Note: Even with seeded variation, identical seeds produce identical output
```

---

## Troubleshooting

### Symbols Not Showing in Quick Help

**Problem:** Option+click in Xcode shows "No documentation"

**Solution:**
1. Ensure comment uses `///` (not `//`)
2. Ensure comment precedes the symbol (not after)
3. Ensure symbol is `public` (not `private` or `internal`)
4. Rebuild project (Cmd+B)

### Cross-References Not Linking

**Problem:** Symbol references in `` ``backticks`` `` don't become links

**Solution:**
1. Check spelling of symbol name exactly
2. For functions, include parentheses: `` ``funcName()`` ``
3. For functions with parameters: `` ``funcName(param:)`` ``
4. For enum cases: `` ``EnumName.caseName`` ``
5. Rebuild documentation (Cmd+Shift+D)

### Generated Docs Have Warnings

**Problem:** Running `swift package generate-documentation` shows warnings

**Solution:**
1. Check for broken symbol references (`` ``unknownSymbol`` ``)
2. Verify all parameter names match function signature
3. Check for unmatched backticks in code examples
4. Ensure all external links are valid URLs

### Examples Don't Format Correctly

**Problem:** Code in examples appears with incorrect indentation

**Solution:**
1. Use triple-backticks with `swift` language tag:
   ````
   ```swift
   let color = ColorJourneyRGB(...)
   ```
   ````
2. Indent code inside examples (preserve relative indentation)
3. Ensure backticks are on their own lines (not inline)

---

## References

- **[Swift-DocC Official Blog](https://www.swift.org/blog/swift-docc/)**
- **[Apple Developer Documentation](https://developer.apple.com/documentation/docc)**
- **[DocC Markup Reference](https://www.swift.org/documentation/docc/documenting-a-swift-framework)**
- **[ColorJourney DOCUMENTATION.md](./DOCUMENTATION.md)** - Full documentation standards

---

## Template: Copy-Paste Starting Points

### Function Template

```swift
/// One-line summary of what this function does.
///
/// Longer description explaining behavior, use cases, and why you'd call this.
///
/// ## Example
///
/// ```swift
/// let result = myFunction(param: 42)
/// print(result)  // Prints the expected output
/// ```
///
/// - Parameter param: Description of this parameter [valid range]
/// - Returns: Description of what is returned
///
/// - Note: Important caveat or guarantee
/// - SeeAlso: ``RelatedFunction()``, ``RelatedType``
public func myFunction(param: Int) -> String
```

### Type Template

```swift
/// One-line summary of what this type represents.
///
/// Longer description explaining when you'd use this type, what it does,
/// and how it fits into the API.
///
/// ## Creating a Type
///
/// ```swift
/// let instance = MyType(property: value)
/// ```
///
/// ## Usage
///
/// Describe typical usage patterns and examples.
///
/// - SeeAlso: ``RelatedType``, ``UtilityFunction()``
public struct MyType {
    /// Description of this property
    public var property: Int
}
```

### Enum Template

```swift
/// One-line summary of what this enum represents.
///
/// Longer description explaining the concept and when you'd use each case.
///
/// ## Cases
///
/// - `.option1`: Description of when to use this case
/// - `.option2`: Description of when to use this case
///
/// ## Example
///
/// ```swift
/// let choice: MyEnum = .option1
/// ```
///
/// - SeeAlso: ``RelatedType``
public enum MyEnum {
    /// Used when [condition]
    case option1
    /// Used when [condition]
    case option2
}
```

---

**Happy documenting!** Swift-DocC makes documentation easy and automatic.

