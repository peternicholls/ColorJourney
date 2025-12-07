# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

## [1.0.0] - 2025-12-06

### Added
- Initial public release
- Core C library with OKLab color space operations
- Swift wrapper with type-safe configuration
- Complete API documentation
- Example code and usage patterns
- Performance optimizations for real-time color generation

[Unreleased]: https://github.com/yourusername/ColorJourney/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/ColorJourney/releases/tag/v1.0.0
