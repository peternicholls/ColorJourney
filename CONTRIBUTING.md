# Contributing to Color Journey

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)

## Code of Conduct

This project follows a simple code of conduct:
- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what's best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Code sample** demonstrating the issue
- **Platform/OS version** (iOS version, macOS version, etc.)
- **Swift version** if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear, descriptive title**
- **Provide detailed description** of the proposed feature
- **Explain why this enhancement would be useful**
- **Provide examples** of how it would work
- **Consider backwards compatibility**

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Setup

### Prerequisites

- Xcode 14.0 or later (for Swift development)
- Swift 5.9 or later
- GCC or Clang (for C development)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/ColorJourney.git
cd ColorJourney

# Build with Swift Package Manager
swift build

# Run tests
swift test

# Or open in Xcode
open Package.swift
```

### Project Structure

```
ColorJourney/
├── Sources/
│   ├── CColorJourney/          # C core library
│   │   ├── include/
│   │   │   └── ColorJourney.h  # Public C API
│   │   └── ColorJourney.c      # Implementation
│   └── ColorJourney/           # Swift wrapper
│       └── ColorJourney.swift   # Swift API
├── Examples/                     # Usage examples
└── Tests/                        # Test suite
```

## Coding Standards

### Documentation Standards

**All contributions must follow the documentation standards in [DOCUMENTATION.md](DOCUMENTATION.md).**

Key requirements:
1. **Public APIs must be fully documented** with appropriate comment style:
   - C code: Doxygen format (`@param`, `@return`, `@brief`)
   - Swift code: DocC format (`///` with structured sections)

2. **Use consistent terminology** from the [Terminology Glossary](DOCUMENTATION.md#terminology-glossary)
   - Never invent new terms; update the glossary if needed
   - Examples: "journey", "anchor color", "OKLab", "discrete palette", "perceptual distance"

3. **Complex algorithms must be explained** with a block comment including:
   - Purpose and trade-offs
   - Why this approach was chosen
   - References to published sources or design documents

4. **All documentation must pass the [Review Checklist](DOCUMENTATION.md#review-checklist)**
   - Completeness: all APIs documented
   - Clarity: terminology consistent, no vague language
   - References: design decisions cited, external links valid
   - Format: correct Doxygen/DocC format

### C Code

- Follow C99 standard
- Use `snake_case` for functions and variables
- Prefix all public symbols with `CJ_`
- Keep functions focused and small
- Comment complex algorithms with [ALGORITHM blocks](DOCUMENTATION.md#algorithm-block-comment-complex-logic)
- Optimize for performance but maintain readability
- Use `const` for immutable parameters
- Always check for null pointers
- Document memory ownership (who allocates, who frees)

```c
/**
 * @brief Compute perceptual distance in OKLab space.
 *
 * @param a Color in OKLab space
 * @param b Color in OKLab space
 * @return Perceptual distance (ΔE) as Euclidean distance in OKLab
 *
 * @note Deterministic: identical inputs always produce identical output.
 */
float CJ_delta_e(CJ_Lab a, CJ_Lab b);
```

### Swift Code

- Follow Swift API Design Guidelines
- Use `PascalCase` for types, `camelCase` for functions/properties
- Prefer value types (structs) over reference types
- Use enums for configuration options
- Document all public APIs with DocC comments (see [template](DOCUMENTATION.md#swift-function-documentation-docc))
- Keep functions pure when possible
- Use `guard` for early returns

```swift
/// Generates a discrete palette of distinct colors from the journey.
/// 
/// - Parameters:
///   - count: Number of colors to generate (≥ 1)
///   - seed: Optional seeded variation for deterministic micro-variation
/// - Returns: Array of `count` Color objects in sRGB
/// - Throws: `ColorJourneyError.invalidCount` if count < 1
///
/// - Note: Perceptual contrast is automatically enforced between adjacent colors
/// - SeeAlso: ``sample(at:)`` for continuous sampling
public func discrete(count: Int, seed: UInt64? = nil) throws -> [Color]
```

### Documentation

- **All public APIs must be documented** (C: Doxygen, Swift: DocC)
- **Include usage examples** in function/type documentation
- **Update README.md** for significant API changes
- **Update CHANGELOG.md** with all user-facing changes
- **Use clear, concise language** with consistent terminology
- **Reference external documents** properly (see [External References](DOCUMENTATION.md#external-references))
- **Run documentation tools** before submitting PR (see [Tools & Generation](DOCUMENTATION.md#tools--generation))

## Submitting Changes

### Commit Messages

Follow conventional commit format:

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(journey): add exponential easing option

Adds support for exponential easing curves in journey interpolation,
allowing for more dramatic color transitions.

Closes #42
```

```
fix(oklab): correct hue wrapping for negative values

Previously negative hue values weren't properly normalized.
This ensures all hue values are within [0, 2π).

Fixes #38
```

### Pull Request Guidelines

- Keep changes focused and atomic
- Update documentation for API changes
- Add tests for new features
- Ensure all tests pass
- Update CHANGELOG.md
- Reference related issues

### Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, your PR will be merged
4. Your contribution will be credited in the release notes

## Testing

### Running Tests

```bash
swift test
```

### Writing Tests

- Test public APIs
- Test edge cases
- Test error conditions
- Keep tests focused and readable

Example:
```swift
func testSingleAnchorJourney() {
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5),
            style: .balanced
        )
    )
    
    let color = journey.sample(at: 0.5)
    XCTAssertGreaterThan(color.r, 0.0)
    XCTAssertLessThan(color.r, 1.0)
}
```

## Performance Considerations

- The C core is optimized for speed
- Avoid unnecessary allocations in hot paths
- Profile before optimizing
- Document performance-critical code
- Consider cache friendliness for batch operations

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion in GitHub Discussions
- Reach out to maintainers

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for their contributions
- README.md contributors section (if significant)
- Release notes

Thank you for contributing to Color Journey! 🎨
