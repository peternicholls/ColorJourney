# ColorJourney Feature Playground

An interactive Swift Playground for exploring and validating all ColorJourney features.

## Overview

This Playground provides hands-on demonstrations of every public API in the ColorJourney library. Built on the proven SwatchDemo CLI tool, it offers visual, interactive examples perfect for learning, testing, and fine-tuning color palettes.

## Contents

### Pages

1. **Introduction** - Getting started and overview
2. **Color Basics** - `ColorJourneyRGB` type, initialization, platform conversions
3. **Journey Styles** - All 6 pre-configured styles with visual comparison
4. **Access Patterns** - Subscript, discrete(), lazy sequences, determinism verification
5. **Configuration** - Anchors, biases, loop modes, variation, and customization
6. **Advanced Use Cases** - Real-world patterns and best practices

### Shared Utilities

- `ColorUtilities.swift` - ANSI color rendering, formatting helpers, comparison utilities

## Usage

### macOS with Xcode

1. Open the ColorJourney package in Xcode
2. Build the package: Product → Build (⌘B)
3. Open `FeaturePlayground.playground`
4. Ensure the ColorJourney scheme is selected
5. Navigate through pages using the page navigator
6. View output in Xcode's Debug Area (Console)

### Requirements

- macOS 10.15 or later
- Xcode 14.0 or later
- Swift 5.9 or later

## Visual Output

The Playground uses ANSI color codes to render color swatches in the console output. For best results:

- View output in Xcode's Debug Area
- Use a terminal/console with 24-bit color support
- Colors appear as colored Unicode block characters (█)

## Learning Path

**New to ColorJourney?** Follow this path:

1. Start with **Introduction** to understand the basics
2. Learn **Color Basics** to work with RGB colors
3. Explore **Journey Styles** to see preset configurations
4. Master **Access Patterns** to understand incremental generation
5. Deep dive into **Configuration** for customization
6. Study **Advanced Use Cases** for real-world patterns

**Quick exploration?** Jump to:

- **Journey Styles** - See all presets in action
- **Access Patterns** - Understand the core concept
- **Advanced Use Cases** - Real-world examples

## Key Features Demonstrated

### Core APIs
- `ColorJourneyRGB` - Color type and initialization
- `ColorJourney` - Main palette generator
- `ColorJourneyConfig` - Configuration builder
- `JourneyStyle` - Preset style enumeration

### Access Patterns
- Subscript: `journey[i]`
- Index method: `journey.discrete(at: i)`
- Batch generation: `journey.discrete(count: N)`
- Range access: `journey.discrete(range: 0..<N)`
- Lazy sequence: `journey.discreteColors.prefix(N)`
- Continuous sampling: `journey.sample(at: t)`

### Configuration Options
- **Anchors** - Single vs multi-anchor
- **Lightness bias** - Darker, neutral, lighter
- **Chroma bias** - Muted, neutral, vivid
- **Contrast level** - Low, medium, high
- **Temperature bias** - Cool, neutral, warm
- **Loop mode** - Open, closed, ping-pong
- **Mid-journey vibrancy** - Energy at journey center
- **Variation** - Deterministic micro-changes

### Journey Styles
- `.balanced` - Neutral, versatile default
- `.pastelDrift` - Light, muted, sophisticated
- `.vividLoop` - Saturated, high-contrast loop
- `.nightMode` - Dark, subdued for dark UIs
- `.warmEarth` - Warm, earthy character
- `.coolSky` - Cool, light, professional

## Real-World Use Cases

The Playground demonstrates practical patterns from SwatchDemo:

1. **Progressive UI Building** - Timeline tracks added incrementally
2. **Tag Systems** - Batch initial tags, add more later
3. **Responsive Layouts** - Adapt to changing column counts
4. **Data Visualization** - Charts with variable categories
5. **Gradients** - Smooth color transitions
6. **Multi-Anchor Transitions** - Brand color interpolation
7. **Accessibility** - High-contrast palettes
8. **Dark Mode** - Optimized for dark backgrounds

## Architecture

```
FeaturePlayground.playground/
├── contents.xcplayground           # Playground manifest
├── Pages/
│   ├── Introduction.xcplaygroundpage/
│   ├── 01-ColorBasics.xcplaygroundpage/
│   ├── 02-JourneyStyles.xcplaygroundpage/
│   ├── 03-AccessPatterns.xcplaygroundpage/
│   ├── 04-Configuration.xcplaygroundpage/
│   └── 05-AdvancedUseCases.xcplaygroundpage/
└── Resources/
    └── ColorUtilities.swift        # Shared utilities
```

## Code Reuse

This Playground reuses and adapts code from:
- **SwatchDemo** - ANSI color utilities, demo patterns
- **ColorJourney** - Production Swift wrapper APIs

All examples are tested and validated to ensure correctness.

## Extending the Playground

To add new pages:

1. Create a new `.xcplaygroundpage` directory in `Pages/`
2. Add `Contents.swift` with your demonstration code
3. Update `contents.xcplayground` to include the new page
4. Use utilities from `Resources/ColorUtilities.swift`
5. Follow existing page structure for consistency

## Troubleshooting

**Playground won't compile?**
- Ensure ColorJourney package is built (⌘B in Xcode)
- Check that the correct scheme is selected
- Clean and rebuild: Product → Clean Build Folder

**Colors not showing?**
- ANSI colors require terminal/console support
- View output in Xcode's Debug Area
- Some console views may not support 24-bit color

**Import errors?**
- Verify ColorJourney module is accessible
- Check Package.swift configuration
- Restart Xcode if needed

## Related Resources

- [ColorJourney README](../../README.md) - Main library documentation
- [SwatchDemo](../SwatchDemo/) - CLI demonstration tool
- [API Documentation](../../Docs/) - Generated API docs
- [Contributing Guide](../../CONTRIBUTING.md) - Contribution guidelines

## Maintenance

This Playground is synchronized with ColorJourney APIs. When adding or changing public APIs:

1. Update relevant Playground pages
2. Test all code samples
3. Update this README if structure changes
4. Verify compilation in CI/CD

See [AGENTS.md](../../AGENTS.md) for synchronization requirements.

## License

Same as ColorJourney library. See [LICENSE](../../LICENSE) for details.

---

**Enjoy exploring ColorJourney!** 🎨

For questions or issues, please file an issue on GitHub or consult the main documentation.
