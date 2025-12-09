# Documentation Quick Reference

**Fast lookup for common documentation tasks**

## Generate Documentation

### Local Development
```bash
# Generate for IDE (includes indexing)
swift package generate-documentation

# View locally
open .build/documentation
```

### For GitHub Pages
```bash
# Generate for static hosting at github.io/ColorJourney
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path ColorJourney \
  --output-path ./docs
```

### For Root Domain
```bash
# Generate for root domain (e.g., docs.example.com)
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --output-path ./docs
```

---

## Document Swift Code

### Template: Function

```swift
/// One-line summary.
///
/// Detailed description explaining behavior and use cases.
///
/// ## Example
///
/// ```swift
/// let result = myFunc(param: value)
/// ```
///
/// - Parameter param: What this parameter does
/// - Returns: What gets returned
/// - SeeAlso: ``RelatedFunc()``, ``RelatedType``
public func myFunc(param: Int) -> String
```

### Template: Type

```swift
/// One-line summary of what this type represents.
///
/// Detailed description and usage.
///
/// - SeeAlso: ``RelatedType``
public struct MyType {
    /// Description of property
    public var property: Int
}
```

### Template: Enum

```swift
/// One-line summary.
///
/// Detailed description.
///
/// ## Cases
///
/// - `.option1`: When to use this
/// - `.option2`: When to use that
public enum MyEnum {
    case option1
    case option2
}
```

---

## DocC Syntax

### Symbol References
```swift
// Type
``ColorJourneyConfig``

// Function
``sample(at:)``

// Function with multiple params
``discrete(count:seed:)``

// Enum case
``JourneyStyle.balanced``

// Property
``anchors``
```

### Structured Sections
```swift
/// - Parameters:
///   - name: Description
///
/// - Returns: Description
///
/// - Throws: Error types
///
/// - Note: Important info
///
/// - Attention: Critical info
///
/// - SeeAlso: ``RelatedSymbol``
```

### External Links
```swift
/// - SeeAlso: [OKLab](https://bottosson.github.io/posts/oklab/)
```

---

## Standards

### Terminology
- **Journey** - Path through color space
- **Anchor** - Starting color(s)
- **Sampling** - Querying colors from journey
- **Palette** - Set of discrete colors
- **OKLab** - Perceptually uniform color space
- **ΔE** - Perceptual distance in OKLab

### Language
- ✅ Use perceptual terms: "vivid", "warm", "soft"
- ❌ Don't use technical jargon: "1.4x multiplier"
- ✅ Explain emotional impact
- ✅ Include examples
- ✅ Link related symbols

### Examples
- ✅ 5-15 lines
- ✅ Runnable code
- ✅ Typical usage
- ❌ Don't include error handling
- ❌ Don't document edge cases

---

## Files

| File | Purpose |
|------|---------|
| **DOCUMENTATION.md** | Full standards, terminology, templates |
| **SWIFT_DOCC_GUIDE.md** | Complete DocC format guide |
| **SWIFT_DOCC_PLUGIN_GUIDE.md** | Publishing & multi-platform setup |
| **ARCHITECTURE.md** | System design & data flow |
| **Sources/ColorJourney/ColorJourney.swift** | Swift API documentation (use `///`) |
| **Sources/CColorJourney/include/ColorJourney.h** | C API documentation (Doxygen format) |

---

## Workflows

### Adding New Public Function

1. Write `///` doc comment first
2. Include example showing typical usage
3. Document all parameters and return value
4. Link to related symbols with backticks
5. Rebuild: `swift package generate-documentation`
6. Check for errors/warnings in output

### Updating Existing Docs

1. Edit `///` comment in source file
2. Update terminology if needed (add to DOCUMENTATION.md glossary)
3. Rebuild documentation
4. Commit changes with description

### Publishing Docs

1. Generate: `swift package --allow-writing-to-directory ./docs generate-documentation ...`
2. Commit: `git add docs/ && git commit -m "docs: publish"`
3. Push: `git push origin main`
4. GitHub Actions publishes to Pages automatically

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Symbol reference not linking | Check spelling, use exact casing, include `()` for functions |
| Doc generation fails | Check for syntax errors in `///` comments, unmatched backticks |
| Docs not updating in Xcode | Build documentation: Cmd+Shift+D |
| GitHub Pages shows 404 | Verify `--hosting-base-path` matches actual URL path |
| Broken markdown in examples | Use triple backticks with `swift` language tag |

---

## Links

- **DOCUMENTATION.md** — [Full API documentation standards](DOCUMENTATION.md)
- **SWIFT_DOCC_GUIDE.md** — [DocC format guide](SWIFT_DOCC_GUIDE.md)
- **SWIFT_DOCC_PLUGIN_GUIDE.md** — [Publishing guide](SWIFT_DOCC_PLUGIN_GUIDE.md)
- **[Swift-DocC Blog](https://www.swift.org/blog/swift-docc/)**
- **[Swift-DocC Plugin](https://swiftlang.github.io/swift-docc-plugin/)**

