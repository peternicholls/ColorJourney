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

### C Code

- Follow C99 standard
- Use `snake_case` for functions and variables
- Prefix all public symbols with `cj_` or `CJ_`
- Keep functions focused and small
- Comment complex algorithms
- Optimize for performance but maintain readability
- Use `const` for immutable parameters
- Always check for null pointers

```c
// Good example
float cj_delta_e(CJ_Lab a, CJ_Lab b) {
    float dL = a.L - b.L;
    float da = a.a - b.a;
    float db = a.b - b.b;
    return sqrtf(dL * dL + da * da + db * db);
}
```

### Swift Code

- Follow Swift API Design Guidelines
- Use `PascalCase` for types, `camelCase` for functions/properties
- Prefer value types (structs) over reference types
- Use enums for configuration options
- Document public APIs with DocC-style comments
- Keep functions pure when possible
- Use `guard` for early returns

```swift
// Good example
public func sample(at t: Float) -> ColorJourneyRGB {
    guard let handle = handle else {
        return ColorJourneyRGB(r: 0, g: 0, b: 0)
    }
    
    let rgb = cj_journey_sample(handle, t)
    return ColorJourneyRGB(r: rgb.r, g: rgb.g, b: rgb.b)
}
```

### Documentation

- Document all public APIs
- Include usage examples in documentation
- Update README.md for significant changes
- Add entries to CHANGELOG.md
- Use clear, concise language

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
