# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Release Entry Template

When cutting a new release, create a new section following this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features, presets, or public APIs

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes or corrections

### Deprecated
- Features marked for removal in future versions

### Removed
- Features or APIs removed in this release

### Security
- Security-related fixes or disclosures

### Performance
- Performance improvements or optimizations

### Notes
- Swift version requirement: ≥X.Y
- C core version requirement: ≥X.Y.Z
- Platform support: [list platforms with minimum versions]
```

**Guidelines**:
- Use semantic versioning for all releases (MAJOR.MINOR.PATCH)
- Tag releases as `vX.Y.Z` (e.g., `v1.0.0`)
- Include version mapping note: "Requires C core ≥vX.Y.Z" for Swift releases
- Link to GitHub releases: `[X.Y.Z]: https://github.com/peternicholls/ColorJourney/releases/tag/vX.Y.Z`
- Document breaking changes clearly in the release notes
- For multi-language releases, separate [C] and [Swift] sections if versions differ

---

## [Unreleased]

### Added
- (upcoming features)

### Fixed
- (upcoming fixes)

## [1.0.0] - 2025-12-09

### Added
- Initial release of Color Journey System
- OKLab-based perceptually uniform color space operations
- Fast cube root optimization (~3-5x speedup)
- Single and multi-anchor color journeys
- Perceptual biases: lightness, chroma, contrast, temperature
- Mid-journey vibrancy control
- Loop modes: open, closed, ping-pong
- Optional variation layer with deterministic seeding
- Journey style presets: balanced, pastelDrift, vividLoop, nightMode, warmEarth, coolSky
- Continuous sampling (for gradients, animations)
- Discrete palette generation (for UI elements)
- SwiftUI integration with gradient helpers
- AppKit/UIKit color conversions
- Comprehensive documentation and examples
- Pure C core for maximum portability
- Idiomatic Swift wrapper API
- Complete API documentation
- Example code and usage patterns
- Performance optimizations for real-time color generation

### Notes
- Swift version requirement: ≥5.9
- Platform support: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+, visionOS 1+, Linux, Windows

[Unreleased]: https://github.com/peternicholls/ColorJourney/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/peternicholls/ColorJourney/releases/tag/v1.0.0
