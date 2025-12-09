import XCTest
@testable import ColorJourney

final class ColorJourneyTests: XCTestCase {

    // MARK: - RGB & Color Type Tests

    func testRGBInitialization() {
        let color = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
        XCTAssertEqual(color.red, 0.5)
        XCTAssertEqual(color.green, 0.3)
        XCTAssertEqual(color.blue, 0.8)
    }

    func testRGBClamping() {
        let color1 = ColorJourneyRGB(red: 1.5, green: -0.1, blue: 0.5)
        let color2 = ColorJourneyRGB(red: 0.2, green: 0.8, blue: 0.6)

        // Note: RGB values are stored as-is, but should be clamped during conversion
        XCTAssertEqual(color1.red, 1.5)  // Unclamped value stored
        XCTAssertEqual(color1.green, -0.1) // Unclamped value stored
        XCTAssertGreaterThanOrEqual(color2.red, 0)
        XCTAssertLessThanOrEqual(color2.blue, 1)
    }

    // MARK: - Single Anchor Journey Tests

    func testSingleAnchorBalancedJourney() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        // Sample at several points
        let start = journey.sample(at: 0.0)
        let mid = journey.sample(at: 0.5)
        let end = journey.sample(at: 1.0)

        XCTAssertNotNil(start)
        XCTAssertNotNil(mid)
        XCTAssertNotNil(end)

        // All colors should have valid RGB values
        XCTAssertGreaterThanOrEqual(start.red, 0)
        XCTAssertLessThanOrEqual(start.red, 1)
        XCTAssertGreaterThanOrEqual(mid.green, 0)
        XCTAssertLessThanOrEqual(mid.green, 1)
        XCTAssertGreaterThanOrEqual(end.blue, 0)
        XCTAssertLessThanOrEqual(end.blue, 1)
    }

    func testSingleAnchorPastelStyle() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.4, blue: 0.6)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .pastelDrift)
        let journey = ColorJourney(config: config)

        // Pastel style should have lighter colors
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testSingleAnchorVividStyle() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .vividLoop)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.3)
        XCTAssertNotNil(color)
    }

    func testSingleAnchorNightMode() {
        let anchor = ColorJourneyRGB(red: 0.6, green: 0.5, blue: 0.7)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .nightMode)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testSingleAnchorWarmEarth() {
        let anchor = ColorJourneyRGB(red: 0.7, green: 0.4, blue: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .warmEarth)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testSingleAnchorCoolSky() {
        let anchor = ColorJourneyRGB(red: 0.2, green: 0.5, blue: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .coolSky)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    // MARK: - Multi-Anchor Journey Tests

    func testMultiAnchorJourney() {
        let anchors = [
            ColorJourneyRGB(red: 1.0, green: 0.3, blue: 0.3),
            ColorJourneyRGB(red: 0.3, green: 1.0, blue: 0.3),
            ColorJourneyRGB(red: 0.3, green: 0.3, blue: 1.0)
        ]
        let config = ColorJourneyConfig.multiAnchor(anchors, style: .balanced)
        let journey = ColorJourney(config: config)

        let start = journey.sample(at: 0.0)
        let mid = journey.sample(at: 0.5)
        let end = journey.sample(at: 1.0)

        XCTAssertNotNil(start)
        XCTAssertNotNil(mid)
        XCTAssertNotNil(end)
    }

    func testFiveAnchorJourney() {
        let anchors = [
            ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0),
            ColorJourneyRGB(red: 1.0, green: 1.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0),
            ColorJourneyRGB(red: 1.0, green: 0.0, blue: 1.0)
        ]
        let config = ColorJourneyConfig.multiAnchor(anchors, style: .balanced)
        let journey = ColorJourney(config: config)

        // Sample at multiple points through the journey
        for index in 0...10 {
            let parameterT = Float(index) / 10.0
            let color = journey.sample(at: parameterT)
            XCTAssertGreaterThanOrEqual(color.red, 0)
            XCTAssertLessThanOrEqual(color.red, 1)
            XCTAssertGreaterThanOrEqual(color.green, 0)
            XCTAssertLessThanOrEqual(color.green, 1)
            XCTAssertGreaterThanOrEqual(color.blue, 0)
            XCTAssertLessThanOrEqual(color.blue, 1)
        }
    }

    // MARK: - Discrete Palette Tests

    func testDiscretePaletteGeneration() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)

        // All colors should be valid
        for color in palette {
            XCTAssertGreaterThanOrEqual(color.red, 0)
            XCTAssertLessThanOrEqual(color.red, 1)
            XCTAssertGreaterThanOrEqual(color.green, 0)
            XCTAssertLessThanOrEqual(color.green, 1)
            XCTAssertGreaterThanOrEqual(color.blue, 0)
            XCTAssertLessThanOrEqual(color.blue, 1)
        }
    }

    func testLargePaletteGeneration() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 20)
        XCTAssertEqual(palette.count, 20)
    }

    func testDiscreteIndexAccess() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        let color = journey.discrete(at: 3)
        let rangeColor = journey.discrete(range: 3..<4).first

        XCTAssertNotNil(rangeColor)
        XCTAssertEqual(color.red, rangeColor?.red ?? -1, accuracy: 1e-6)
        XCTAssertEqual(color.green, rangeColor?.green ?? -1, accuracy: 1e-6)
        XCTAssertEqual(color.blue, rangeColor?.blue ?? -1, accuracy: 1e-6)
    }

    func testDiscreteRangeMatchesIndividualCalls() {
        let anchor = ColorJourneyRGB(red: 0.2, green: 0.5, blue: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        let range = journey.discrete(range: 1..<5)
        XCTAssertEqual(range.count, 4)

        for (offset, color) in range.enumerated() {
            let single = journey.discrete(at: offset + 1)
            XCTAssertEqual(color.red, single.red, accuracy: 1e-6)
            XCTAssertEqual(color.green, single.green, accuracy: 1e-6)
            XCTAssertEqual(color.blue, single.blue, accuracy: 1e-6)
        }
    }

    func testDiscreteSubscriptAndSequence() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.3, blue: 0.7)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        let subscriptColor = journey[2]
        let atColor = journey.discrete(at: 2)

        XCTAssertEqual(subscriptColor.red, atColor.red, accuracy: 1e-6)
        XCTAssertEqual(subscriptColor.green, atColor.green, accuracy: 1e-6)
        XCTAssertEqual(subscriptColor.blue, atColor.blue, accuracy: 1e-6)

        let sequenceColors = Array(journey.discreteColors.prefix(3))
        let rangeColors = journey.discrete(range: 0..<3)

        XCTAssertEqual(sequenceColors.count, rangeColors.count)
        for (lhs, rhs) in zip(sequenceColors, rangeColors) {
            XCTAssertEqual(lhs.red, rhs.red, accuracy: 1e-6)
            XCTAssertEqual(lhs.green, rhs.green, accuracy: 1e-6)
            XCTAssertEqual(lhs.blue, rhs.blue, accuracy: 1e-6)
        }
    }

    func testSingleColorPalette() {
        let anchor = ColorJourneyRGB(red: 0.6, green: 0.4, blue: 0.5)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 1)
        XCTAssertEqual(palette.count, 1)
        XCTAssertNotNil(palette[0])
    }

    // MARK: - Perceptual Dynamics Tests

    func testLightnessBiasNeutral() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .neutral
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testLightnessBiasLighter() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .lighter
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testLightnessBiasDarker() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .darker
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testChromaBiasNeutral() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .neutral
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testChromaBiasMuted() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .muted
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testChromaBiasVivid() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .vivid
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testContrastLow() {
        let anchors = [
            ColorJourneyRGB(red: 0.4, green: 0.4, blue: 0.4),
            ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .low
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }

    func testContrastMedium() {
        let anchors = [
            ColorJourneyRGB(red: 0.2, green: 0.2, blue: 0.2),
            ColorJourneyRGB(red: 0.8, green: 0.8, blue: 0.8)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .medium
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }

    func testContrastHigh() {
        let anchors = [
            ColorJourneyRGB(red: 0.1, green: 0.1, blue: 0.1),
            ColorJourneyRGB(red: 0.9, green: 0.9, blue: 0.9)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .high
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }

    // MARK: - Temperature Bias Tests

    func testTemperatureBiasWarm() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.temperature = .warm
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testTemperatureBiasCool() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.temperature = .cool
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    // MARK: - Loop Mode Tests

    func testLoopModeOpen() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.loopMode = .open
        let journey = ColorJourney(config: config)

        let start = journey.sample(at: 0.0)
        let end = journey.sample(at: 1.0)
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
    }

    func testLoopModeClosed() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.loopMode = .closed
        let journey = ColorJourney(config: config)

        // In closed loop, start and end should connect smoothly
        let start = journey.sample(at: 0.0)
        let end = journey.sample(at: 1.0)
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
    }

    func testLoopModePingPong() {
        let anchors = [
            ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.loopMode = .pingPong
        let journey = ColorJourney(config: config)

        // Ping-pong should reverse direction at ends
        let colors = (0...20).map { index in
            journey.sample(at: Float(index) / 20.0)
        }
        XCTAssertEqual(colors.count, 21)
    }

    // MARK: - Variation Layer Tests

    func testVariationDisabled() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .off
        let journey = ColorJourney(config: config)

        // Should be deterministic
        let color1 = journey.sample(at: 0.5)
        let color2 = journey.sample(at: 0.5)

        XCTAssertEqual(color1.red, color2.red, accuracy: 0.0001)
        XCTAssertEqual(color1.green, color2.green, accuracy: 0.0001)
        XCTAssertEqual(color1.blue, color2.blue, accuracy: 0.0001)
    }

    func testVariationEnabled() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.hue, .lightness, .chroma])
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 10)
        XCTAssertEqual(palette.count, 10)

        // All colors should still be valid
        for color in palette {
            XCTAssertGreaterThanOrEqual(color.red, 0)
            XCTAssertLessThanOrEqual(color.red, 1)
        }
    }

    func testVariationHueOnly() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.hue])
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testVariationLightnessOnly() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.lightness])
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testVariationChromaOnly() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.chroma])
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testVariationDeterministicSeed() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        let seed: UInt64 = 42

        var config1 = ColorJourneyConfig(anchors: [anchor])
        config1.variation = .subtle(dimensions: [.hue], seed: seed)
        let journey1 = ColorJourney(config: config1)

        var config2 = ColorJourneyConfig(anchors: [anchor])
        config2.variation = .subtle(dimensions: [.hue], seed: seed)
        let journey2 = ColorJourney(config: config2)

        // Same seed should produce same results
        let palette1 = journey1.discrete(count: 5)
        let palette2 = journey2.discrete(count: 5)

        for index in 0..<5 {
            XCTAssertEqual(palette1[index].red, palette2[index].red, accuracy: 0.0001)
            XCTAssertEqual(palette1[index].green, palette2[index].green, accuracy: 0.0001)
            XCTAssertEqual(palette1[index].blue, palette2[index].blue, accuracy: 0.0001)
        }
    }

    // MARK: - Custom Configuration Tests

    func testCustomLightnessBias() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .custom(weight: 0.3)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testCustomChromaBias() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .custom(multiplier: 1.5)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testCustomContrastThreshold() {
        let anchors = [
            ColorJourneyRGB(red: 0.3, green: 0.3, blue: 0.3),
            ColorJourneyRGB(red: 0.7, green: 0.7, blue: 0.7)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .custom(threshold: 0.12)
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }

    // MARK: - Edge Cases & Robustness Tests

    func testBoundaryConditionsT0() {
        let anchor = ColorJourneyRGB(red: 0.6, green: 0.4, blue: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.0)
        XCTAssertGreaterThanOrEqual(color.red, 0)
        XCTAssertLessThanOrEqual(color.red, 1)
    }

    func testBoundaryConditionsT1() {
        let anchor = ColorJourneyRGB(red: 0.6, green: 0.4, blue: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 1.0)
        XCTAssertGreaterThanOrEqual(color.red, 0)
        XCTAssertLessThanOrEqual(color.red, 1)
    }

    func testExtremeBlack() {
        let anchor = ColorJourneyRGB(red: 0.0, green: 0.0, blue: 0.0)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testExtremeWhite() {
        let anchor = ColorJourneyRGB(red: 1.0, green: 1.0, blue: 1.0)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testHighVibrance() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.midJourneyVibrancy = 1.0
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testZeroVibrance() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.midJourneyVibrancy = 0.0
        let journey = ColorJourney(config: config)

        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }

    func testEmptyPalette() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: 0)
        XCTAssertEqual(palette.count, 0)
    }

    // MARK: - Configuration Presets Tests

    func testAllPresets() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        let presets: [JourneyStyle] = [
            .balanced,
            .pastelDrift,
            .vividLoop,
            .nightMode,
            .warmEarth,
            .coolSky
        ]

        for preset in presets {
            let config = ColorJourneyConfig.singleAnchor(anchor, style: preset)
            let journey = ColorJourney(config: config)
            let color = journey.sample(at: 0.5)
            XCTAssertNotNil(color)
        }
    }

    // MARK: - SwiftUI Integration Tests (if available)

    #if canImport(SwiftUI)
    func testSwiftUIConversion() {
        let rgbColor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
        let swiftUIColor = rgbColor.color
        XCTAssertNotNil(swiftUIColor)
    }

    func testGradientGeneration() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let gradient = journey.gradient(stops: 5)
        XCTAssertNotNil(gradient)
    }

    func testLinearGradientGeneration() {
        let anchor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        let linearGradient = journey.linearGradient(stops: 10)
        XCTAssertNotNil(linearGradient)
    }
    #endif

    // MARK: - Performance Tests

    func testLargeDiscretePerformance() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        measure {
            let _ = journey.discrete(count: 100)
        }
    }

    func testManySamplePerformance() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)

        measure {
            for index in 0..<1000 {
                let _ = journey.sample(at: Float(index) / 1000.0)
            }
        }
    }
}
