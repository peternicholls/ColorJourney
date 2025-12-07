/*
 * Colour Journey - Example Usage & Tests
 * Demonstrates various journey configurations
 */

import Foundation

// MARK: - Basic Examples

func basicExamples() {
    print("=== Basic Journey Examples ===\n")
    
    // Example 1: Single anchor, balanced style
    print("1. Single Anchor - Balanced")
    let journey1 = ColourJourney(
        config: .singleAnchor(
            ColourJourneyRGB(r: 0.3, g: 0.5, b: 0.8),
            style: .balanced
        )
    )
    
    let palette1 = journey1.discrete(count: 5)
    for (i, color) in palette1.enumerated() {
        print("  Color \(i): RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
    }
    
    // Example 2: Multi-anchor closed loop
    print("\n2. Multi-Anchor - Closed Loop")
    let journey2 = ColourJourney(config: ColourJourneyConfig(
        anchors: [
            ColourJourneyRGB(r: 1.0, g: 0.2, b: 0.2),
            ColourJourneyRGB(r: 0.2, g: 1.0, b: 0.2),
            ColourJourneyRGB(r: 0.2, g: 0.2, b: 1.0)
        ],
        loopMode: .closed
    ))
    
    let palette2 = journey2.discrete(count: 6)
    for (i, color) in palette2.enumerated() {
        print("  Color \(i): RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
    }
}

// MARK: - Style Preset Examples

func stylePresetExamples() {
    print("\n=== Style Preset Examples ===\n")
    
    let baseColor = ColourJourneyRGB(r: 0.4, g: 0.6, b: 0.8)
    
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
        let journey = ColourJourney(
            config: .singleAnchor(baseColor, style: style)
        )
        
        let colors = journey.discrete(count: 3)
        for (i, color) in colors.enumerated() {
            print("  [\(i)] RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
        }
    }
}

// MARK: - Variation Examples

func variationExamples() {
    print("\n=== Variation Examples ===\n")
    
    let baseColor = ColourJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
    
    // No variation
    print("1. No Variation (Deterministic):")
    let journey1 = ColourJourney(config: ColourJourneyConfig(
        anchors: [baseColor],
        variation: .off
    ))
    let palette1a = journey1.discrete(count: 3)
    let palette1b = journey1.discrete(count: 3)
    print("  First run:  \(formatPalette(palette1a))")
    print("  Second run: \(formatPalette(palette1b))")
    print("  Match: \(palette1a == palette1b)")
    
    // Subtle hue variation
    print("\n2. Subtle Hue Variation (Seeded):")
    let journey2 = ColourJourney(config: ColourJourneyConfig(
        anchors: [baseColor],
        variation: .subtle(dimensions: [.hue], seed: 12345)
    ))
    let palette2 = journey2.discrete(count: 5)
    print("  \(formatPalette(palette2))")
    
    // Multi-dimensional variation
    print("\n3. All Dimensions - Noticeable:")
    let journey3 = ColourJourney(config: ColourJourneyConfig(
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

// MARK: - Continuous Sampling Example

func continuousSamplingExample() {
    print("\n=== Continuous Sampling ===\n")
    
    let journey = ColourJourney(
        config: .singleAnchor(
            ColourJourneyRGB(r: 0.8, g: 0.3, b: 0.5),
            style: .vividLoop
        )
    )
    
    print("Sampling at 10 points along journey:")
    for i in 0..<10 {
        let t = Float(i) / 9.0
        let color = journey.sample(at: t)
        print("  t=\(String(format: "%.2f", t)): RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
    }
}

// MARK: - Advanced Configuration Example

func advancedConfigExample() {
    print("\n=== Advanced Configuration ===\n")
    
    let config = ColourJourneyConfig(
        anchors: [
            ColourJourneyRGB(r: 0.9, g: 0.2, b: 0.3),
            ColourJourneyRGB(r: 0.2, g: 0.8, b: 0.4)
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
    
    let journey = ColourJourney(config: config)
    let palette = journey.discrete(count: 8)
    
    print("Custom configured palette (8 colors):")
    for (i, color) in palette.enumerated() {
        print("  [\(i)] RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
    }
}

// MARK: - Performance Test

func performanceTest() {
    print("\n=== Performance Test ===\n")
    
    let journey = ColourJourney(
        config: .singleAnchor(
            ColourJourneyRGB(r: 0.5, g: 0.5, b: 0.5),
            style: .balanced
        )
    )
    
    let iterations = 10000
    let start = Date()
    
    for i in 0..<iterations {
        let t = Float(i) / Float(iterations)
        _ = journey.sample(at: t)
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

// MARK: - UI Use Case Example

func uiUseCaseExample() {
    print("\n=== UI Use Case Examples ===\n")
    
    // Timeline tracks
    print("1. Timeline Tracks (12 colors):")
    let trackJourney = ColourJourney(
        config: .singleAnchor(
            ColourJourneyRGB(r: 0.4, g: 0.5, b: 0.9),
            style: .balanced
        )
    )
    let trackColors = trackJourney.discrete(count: 12)
    print("  Generated \(trackColors.count) distinct track colors")
    
    // Label system
    print("\n2. Label System (8 categories):")
    let labelJourney = ColourJourney(config: ColourJourneyConfig(
        anchors: [
            ColourJourneyRGB(r: 0.8, g: 0.3, b: 0.3),
            ColourJourneyRGB(r: 0.3, g: 0.8, b: 0.8)
        ],
        contrast: .high,
        loopMode: .closed
    ))
    let labelColors = labelJourney.discrete(count: 8)
    print("  Generated \(labelColors.count) high-contrast label colors")
    
    // Segment markers
    print("\n3. Segment Markers with Variation:")
    let segmentJourney = ColourJourney(config: ColourJourneyConfig(
        anchors: [ColourJourneyRGB(r: 0.6, g: 0.4, b: 0.7)],
        variation: .subtle(dimensions: [.hue, .lightness])
    ))
    let segmentColors = segmentJourney.discrete(count: 20)
    print("  Generated \(segmentColors.count) subtly varied segment colors")
}

// MARK: - Helper Functions

func formatPalette(_ colors: [ColourJourneyRGB]) -> String {
    colors.map { "(\(String(format: "%.2f", $0.r)), \(String(format: "%.2f", $0.g)), \(String(format: "%.2f", $0.b)))" }
        .joined(separator: ", ")
}

// MARK: - Main

func runAllExamples() {
    print("╔════════════════════════════════════════════╗")
    print("║   Colour Journey System - Examples        ║")
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