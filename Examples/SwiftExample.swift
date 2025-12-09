/*
 * ColorJourney - Swift API Usage Examples
 * =======================================
 *
 * This file demonstrates comprehensive usage patterns for the Swift ColorJourney API.
 * Covers:
 *   1. Basic single-anchor and multi-anchor journeys
 *   2. Style presets and perceptual bias configurations
 *   3. Variation modes (determinism, seeded randomness, continuous variation)
 *   4. Continuous sampling and discrete palette generation
 *   5. UI-specific use cases (timeline tracks, labels, segments)
 *   6. Performance characteristics
 *
 * Constitutional Alignment (see .specify/memory/constitution.md):
 * - Principle II: Perceptual Integrity - Demonstrates high-level, designer-centric API
 * - Principle III: Designer-Centric Configuration - Uses descriptive presets and bias controls
 * - Principle IV: Deterministic Output - Shows seeded variation for reproducible results
 *
 * User Story US5: Examples are clear and runnable
 * - Builds via `swift build` or Xcode scheme
 * - All functions demonstrate real-world use cases
 * - Code snippets are verified compilable (see DOCUMENTATION.md)
 */

import Foundation

// MARK: - Basic Examples (US5: Core API Usage)

func basicExamples() {
    print("=== Basic Journey Examples ===\n")

    // MARK: Single Anchor, Balanced Style
    /*
     * Demonstrates the simplest journey configuration:
     *   - One anchor point (e.g., a medium blue)
     *   - Balanced style (moderate contrast, subtle variation)
     *   - 5-color discrete palette
     * 
     * Use case: Simple color system for lightweight UIs or quick prototypes.
     * See Principle III: Designer-centric control via style presets (not parameters).
     */
    print("1. Single Anchor - Balanced")
    let journey1 = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8),
            style: .balanced
        )
    )

    let palette1 = journey1.discrete(count: 5)
    for (index, color) in palette1.enumerated() {
        let rgb = "RGB(\(String(format: "%.2f", color.red)), "
        let gb = "\(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
        print("  Color \(index): \(rgb)\(gb)")
    }

    // MARK: Multi-Anchor Closed Loop
    /*
     * Multi-anchor journey transitioning between three distinct color points.
     * 
     * Closed loop mode:
     *   - Colors flow from anchor 0 → 1 → 2 → back to 0
     *   - Useful for cyclical data (time of day, circular progress)
     * 
     * Use case: Color systems for cyclic data visualization or radial UIs.
     * See Principle II: Perceptual continuity maintained across anchor transitions.
     */
    print("\n2. Multi-Anchor - Closed Loop")
    let journey2 = ColorJourney(config: ColorJourneyConfig(
        anchors: [
            ColorJourneyRGB(red: 1.0, green: 0.2, blue: 0.2),
            ColorJourneyRGB(red: 0.2, green: 1.0, blue: 0.2),
            ColorJourneyRGB(red: 0.2, green: 0.2, blue: 1.0)
        ],
        loopMode: .closed
    ))

    let palette2 = journey2.discrete(count: 6)
    for (index, color) in palette2.enumerated() {
        let rgb = "RGB(\(String(format: "%.2f", color.red)), "
        let gb = "\(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
        print("  Color \(index): \(rgb)\(gb)")
    }
}

// MARK: - Style Preset Examples (US5: Designer-Centric Configuration)

func stylePresetExamples() {
    print("\n=== Style Preset Examples ===\n")

    /*
     * Demonstrates the six predefined style presets for single-anchor journeys.
     * Each preset encodes designer-centric visual intents:
     *   - Balanced: Even distribution, moderate contrast
     *   - Pastel Drift: Lighter, lower saturation, soft transitions
     *   - Vivid Loop: Bold, high saturation, closed interpolation
     *   - Night Mode: Darker base, cool tones, high contrast
     *   - Warm Earth: Orange/brown bias, grounded feeling
     *   - Cool Sky: Blue bias, bright, airy feeling
     * 
     * Use case: Quick selection of color palettes without parameter tuning.
     * See Principle III: Styles abstract away lightness, chroma, temperature controls.
     */

    let baseColor = ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.8)

    let styles: [(String, JourneyStyle)] = [
        ("Balanced", .balanced),
        ("Pastel Drift", .pastelDrift),
        ("Vivid Loop", .vividLoop),
        ("Night Mode", .nightMode),
        ("Warm Earth", .warmEarth),
        ("Cool Sky", .coolSky)
    ]

    for (name, style) in styles {
        print("\(name):")
        let journey = ColorJourney(
            config: .singleAnchor(baseColor, style: style)
        )

        let colors = journey.discrete(count: 3)
        for (index, color) in colors.enumerated() {
            let rgb = "RGB(\(String(format: "%.2f", color.red)), "
            let gb = "\(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
            print("  [\(index)] \(rgb)\(gb)")
        }
    }
}

// MARK: - Variation Examples (US5: Determinism & Seeded Randomness)

func variationExamples() {
    print("\n=== Variation Examples ===\n")

    /*
     * Demonstrates the three variation modes:
     *   1. Off (.off): Exact same colors every time (deterministic)
     *   2. Subtle: Small seeded variations (reproducible with same seed)
     *   3. Noticeable: Larger variations across multiple dimensions
     * 
     * See Principle IV: Determinism guarantees allow reproducible designs across sessions.
     * Use seeded variation for:
     *   - User-specific color schemes (seed = user ID)
     *   - Consistent multi-session experiences (same seed = same colors)
     *   - Variation that's auditable and reproducible
     */

    let baseColor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)

    // MARK: No Variation (Fully Deterministic)
    print("1. No Variation (Deterministic):")
    let journey1 = ColorJourney(config: ColorJourneyConfig(
        anchors: [baseColor],
        variation: .off
    ))
    let palette1a = journey1.discrete(count: 3)
    let palette1b = journey1.discrete(count: 3)
    print("  First run:  \(formatPalette(palette1a))")
    print("  Second run: \(formatPalette(palette1b))")
    print("  Match: \(palette1a == palette1b)")

    // MARK: Subtle Hue Variation (Seeded)
    /*
     * Small variations in hue only, reproducible via seed=12345.
     * Use case: Generating user-specific color variations from a base anchor.
     */
    print("\n2. Subtle Hue Variation (Seeded):")
    let journey2 = ColorJourney(config: ColorJourneyConfig(
        anchors: [baseColor],
        variation: .subtle(dimensions: [.hue], seed: 12345)
    ))
    let palette2 = journey2.discrete(count: 5)
    print("  \(formatPalette(palette2))")

    // MARK: Multi-Dimensional Variation (Noticeable)
    /*
     * Larger variations across hue, chroma, and lightness.
     * Use case: Creating diverse color themes with significant visual separation.
     */
    print("\n3. All Dimensions - Noticeable:")
    let journey3 = ColorJourney(config: ColorJourneyConfig(
        anchors: [baseColor],
        variation: VariationConfig(
            enabled: true,
            dimensions: .all,
            strength: .noticeable,
            seed: 67890
        )
    ))
    let palette3 = journey3.discrete(count: 5)
    print("  \(formatPalette(palette3))")
}

// MARK: - Continuous Sampling Example (US5: Gradient Generation)

func continuousSamplingExample() {
    print("\n=== Continuous Sampling ===\n")

    /*
     * Demonstrates smooth interpolation at arbitrary points along the journey.
     * 
     * Use cases:
     *   - Gradient generation: 256+ colors for smooth transitions
     *   - Progress indicators: Color mapped to percentage (t = progress / 100.0)
     *   - Data visualization: Color mapped to continuous value (t = (value - min) / (max - min))
     *   - Real-time animations: Update color as parameter changes
     * 
     * Parameter t (0.0 to 1.0) represents normalized position along the journey.
     * See Principle II: Perceptually smooth spacing maintained across entire range.
     */

    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(red: 0.8, green: 0.3, blue: 0.5),
            style: .vividLoop
        )
    )

    print("Sampling at 10 points along journey:")
    for index in 0..<10 {
        let parameterT = Float(index) / 9.0
        let color = journey.sample(at: parameterT)
        let tVal = String(format: "%.2f", parameterT)
        let rgb = "RGB(\(String(format: "%.2f", color.red)), "
        let gb = "\(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
        print("  t=\(tVal): \(rgb)\(gb)")
    }
}

// MARK: - Advanced Configuration Example (US5: Custom Bias Controls)

func advancedConfigExample() {
    print("\n=== Advanced Configuration ===\n")

    /*
     * Demonstrates explicit control over perceptual biases and design parameters.
     * 
     * Parameters:
     *   - lightness: Weight for brightness (range: 0.0-1.0)
     *   - chroma: Saturation multiplier (range: 0.5-2.0)
     *   - contrast: Perceptual distinction level (low/medium/high)
     *   - midJourneyVibrancy: Boost mid-journey colors (range: 0.0-1.0)
     *   - temperature: Color warmth bias (cool/neutral/warm)
     *   - loopMode: How journey wraps (open/closed/pingPong)
     *   - variation: Seeded randomness configuration
     * 
     * See Principle III: Designer-centric parameters expressed in perceptual terms.
     * Use case: Fine-tuned palettes for specific brand or design requirements.
     */

    let config = ColorJourneyConfig(
        anchors: [
            ColorJourneyRGB(red: 0.9, green: 0.2, blue: 0.3),
            ColorJourneyRGB(red: 0.2, green: 0.8, blue: 0.4)
        ],
        lightness: .custom(weight: 0.2),      // Slightly lighter
        chroma: .custom(multiplier: 1.3),     // More saturated
        contrast: .high,                       // Strong distinction
        midJourneyVibrancy: 0.6,              // Boost midpoint
        temperature: .warm,                    // Warm bias
        loopMode: .pingPong,
        variation: VariationConfig(
            enabled: true,
            dimensions: [.hue, .chroma],
            strength: .subtle,
            seed: 0xDEADBEEF
        )
    )

    let journey = ColorJourney(config: config)
    let palette = journey.discrete(count: 8)

    print("Custom configured palette (8 colors):")
    for (index, color) in palette.enumerated() {
        let rgb = "RGB(\(String(format: "%.2f", color.red)), "
        let gb = "\(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
        print("  [\(index)] \(rgb)\(gb)")
    }
}

// MARK: - Performance Test (US5: Benchmarking)

func performanceTest() {
    print("\n=== Performance Test ===\n")

    /*
     * Benchmarks core operations to demonstrate performance characteristics.
     * 
     * Expected results (see Principle I):
     *   - Sample: <1 microsecond per call
     *   - Discrete (100 colors): <1 millisecond
     *   - Zero allocations (reuses journey state)
     *   - Memory usage: ~256 bytes per journey object
     * 
     * Use case: Validate that real-time color generation is feasible for
     * high-frequency UI updates (60+ FPS animations).
     */

    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5),
            style: .balanced
        )
    )

    let iterations = 10000
    let start = Date()

    for index in 0..<iterations {
        let parameterT = Float(index) / Float(iterations)
        _ = journey.sample(at: parameterT)
    }

    let elapsed = Date().timeIntervalSince(start)
    let samplesPerSecond = Double(iterations) / elapsed

    print("Sampled \(iterations) colors in \(String(format: "%.3f", elapsed))s")
    print("Performance: \(String(format: "%.0f", samplesPerSecond)) samples/second")

    // Discrete palette generation
    let start2 = Date()
    _ = journey.discrete(count: 100)
    let elapsed2 = Date().timeIntervalSince(start2)

    print("Generated 100-color discrete palette in \(String(format: "%.3f", elapsed2))s")
}

// MARK: - UI Use Case Examples (US5: Real-World Applications)

func uiUseCaseExample() {
    print("\n=== UI Use Case Examples ===\n")

    /*
     * Demonstrates practical application patterns for UI color systems.
     */

    // MARK: Timeline Tracks (12+ Distinct Colors)
    /*
     * Use case: Video editing, timeline visualization
     * Each track needs a visually distinct color without feeling chaotic.
     */
    print("1. Timeline Tracks (12 colors):")
    let trackJourney = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.9),
            style: .balanced
        )
    )
    let trackColors = trackJourney.discrete(count: 12)
    print("  Generated \(trackColors.count) distinct track colors")

    // MARK: Label System (High Contrast)
    /*
     * Use case: Data visualization labels, category colors
     * Requires high contrast between adjacent colors and good perceptual separation.
     */
    print("\n2. Label System (8 categories):")
    let labelJourney = ColorJourney(config: ColorJourneyConfig(
        anchors: [
            ColorJourneyRGB(red: 0.8, green: 0.3, blue: 0.3),
            ColorJourneyRGB(red: 0.3, green: 0.8, blue: 0.8)
        ],
        contrast: .high,
        loopMode: .closed
    ))
    let labelColors = labelJourney.discrete(count: 8)
    print("  Generated \(labelColors.count) high-contrast label colors")

    // MARK: Segment Markers with Variation
    /*
     * Use case: Accessibility-aware color systems (users get unique but consistent colors)
     * Subtle variation makes colors more interesting while maintaining auditability.
     */
    print("\n3. Segment Markers with Variation:")
    let segmentJourney = ColorJourney(config: ColorJourneyConfig(
        anchors: [ColorJourneyRGB(red: 0.6, green: 0.4, blue: 0.7)],
        variation: .subtle(dimensions: [.hue, .lightness])
    ))
    let segmentColors = segmentJourney.discrete(count: 20)
    print("  Generated \(segmentColors.count) subtly varied segment colors")
}

// MARK: - Helper Functions

/*
 * Formats an array of RGB colors as a compact string for display.
 * Each color is shown as (r, g, b) with 2 decimal places.
 */
func formatPalette(_ colors: [ColorJourneyRGB]) -> String {
    colors.map {
        let r = String(format: "%.2f", $0.red)
        let g = String(format: "%.2f", $0.green)
        let b = String(format: "%.2f", $0.blue)
        return "(\(r), \(g), \(b))"
    }.joined(separator: ", ")
}

// MARK: - Main Entry Point

/*
 * Runs all example demonstrations in sequence.
 * Each example function demonstrates a specific API pattern or use case.
 */
func runAllExamples() {
    print("╔════════════════════════════════════════════╗")
    print("║   Color Journey System - Examples          ║")
    print("╚════════════════════════════════════════════╝\n")

    basicExamples()
    stylePresetExamples()
    variationExamples()
    continuousSamplingExample()
    advancedConfigExample()
    uiUseCaseExample()
    performanceTest()

    print("\n✅ All examples completed successfully!")
}

// Uncomment to run:
// runAllExamples()
