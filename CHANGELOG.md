# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.3] - 2025-12-09

### Changed
- **BREAKING**: Migrated to semantic versioning without 'v' prefix (following HexColor pattern)
- Simplified Package.swift to minimal structure (removed explicit source paths, executable targets)
- Streamlined package configuration for improved SPM/CocoaPods compatibility

### Fixed
- Removed 'v' prefix from git tags to align with Swift Package Manager best practices
- CocoaPods distribution now follows industry-standard Xcode-native pattern

### Notes
- **Migration**: Old v1.0.2 tag replaced with 1.0.3 (no 'v' prefix)
- Swift version requirement: ≥5.9
- Platform support: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+, visionOS 1+
- Following [HexColor publishing pattern](https://kevinabram1000.medium.com/how-to-build-and-share-your-own-swift-library-with-swift-package-manager-1905fcc4716b)

## [1.0.2] - 2025-12-09

### Added
- Initial release of Color Journey System
- OKLab-based perceptually uniform color space matrix transformations, with CIECAM02 adaptations
- Extreme-performance color journey generation algorithms due to fast cube root optimization (10000 palette swatches in 2 microseconds)
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

### Fixed
- Unified release packaging with both Swift wrapper and C core in single archive
- Release assets simplified: ColorJourney-1.0.2.tar.gz and ColorJourney-1.0.2.zip only
- Both release archives always include the C core (Sources/CColorJourney/) as essential for API functionality

### Notes
- First stable public release
- Release assets: ColorJourney-1.0.2.tar.gz and ColorJourney-1.0.2.zip, both containing Swift wrapper and C core
- Swift version requirement: ≥5.9
- Platform support: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+, visionOS 1+, Linux, Windows

[Unreleased]: https://github.com/peternicholls/ColorJourney/compare/1.0.3...HEAD
[1.0.3]: https://github.com/peternicholls/ColorJourney/releases/tag/1.0.3
[1.0.2]: https://github.com/peternicholls/ColorJourney/releases/tag/v1.0.2
