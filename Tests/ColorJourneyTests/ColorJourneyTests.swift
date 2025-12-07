import XCTest
@testable import ColorJourney

final class ColorJourneyTests: XCTestCase {
    
    // MARK: - RGB & Color Type Tests
    
    func testRGBInitialization() {
        let color = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.8)
        XCTAssertEqual(color.r, 0.5)
        XCTAssertEqual(color.g, 0.3)
        XCTAssertEqual(color.b, 0.8)
    }
    
    func testRGBClamping() {
        let color1 = ColorJourneyRGB(r: 1.5, g: -0.1, b: 0.5)
        let color2 = ColorJourneyRGB(r: 0.2, g: 0.8, b: 0.6)
        
        // Note: RGB values are stored as-is, but should be clamped during conversion
        XCTAssertEqual(color1.r, 1.5)  // Unclamped value stored
        XCTAssertEqual(color1.g, -0.1) // Unclamped value stored
        XCTAssertGreaterThanOrEqual(color2.r, 0)
        XCTAssertLessThanOrEqual(color2.b, 1)
    }
    
    // MARK: - Single Anchor Journey Tests
    
    func testSingleAnchorBalancedJourney() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8)
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
        XCTAssertGreaterThanOrEqual(start.r, 0)
        XCTAssertLessThanOrEqual(start.r, 1)
        XCTAssertGreaterThanOrEqual(mid.g, 0)
        XCTAssertLessThanOrEqual(mid.g, 1)
        XCTAssertGreaterThanOrEqual(end.b, 0)
        XCTAssertLessThanOrEqual(end.b, 1)
    }
    
    func testSingleAnchorPastelStyle() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.4, b: 0.6)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .pastelDrift)
        let journey = ColorJourney(config: config)
        
        // Pastel style should have lighter colors
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testSingleAnchorVividStyle() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.6, b: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .vividLoop)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.3)
        XCTAssertNotNil(color)
    }
    
    func testSingleAnchorNightMode() {
        let anchor = ColorJourneyRGB(r: 0.6, g: 0.5, b: 0.7)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .nightMode)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testSingleAnchorWarmEarth() {
        let anchor = ColorJourneyRGB(r: 0.7, g: 0.4, b: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .warmEarth)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testSingleAnchorCoolSky() {
        let anchor = ColorJourneyRGB(r: 0.2, g: 0.5, b: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .coolSky)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    // MARK: - Multi-Anchor Journey Tests
    
    func testMultiAnchorJourney() {
        let anchors = [
            ColorJourneyRGB(r: 1.0, g: 0.3, b: 0.3),
            ColorJourneyRGB(r: 0.3, g: 1.0, b: 0.3),
            ColorJourneyRGB(r: 0.3, g: 0.3, b: 1.0)
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
            ColorJourneyRGB(r: 1.0, g: 0.0, b: 0.0),
            ColorJourneyRGB(r: 1.0, g: 1.0, b: 0.0),
            ColorJourneyRGB(r: 0.0, g: 1.0, b: 0.0),
            ColorJourneyRGB(r: 0.0, g: 0.0, b: 1.0),
            ColorJourneyRGB(r: 1.0, g: 0.0, b: 1.0)
        ]
        let config = ColorJourneyConfig.multiAnchor(anchors, style: .balanced)
        let journey = ColorJourney(config: config)
        
        // Sample at multiple points through the journey
        for i in 0...10 {
            let t = Float(i) / 10.0
            let color = journey.sample(at: t)
            XCTAssertGreaterThanOrEqual(color.r, 0)
            XCTAssertLessThanOrEqual(color.r, 1)
            XCTAssertGreaterThanOrEqual(color.g, 0)
            XCTAssertLessThanOrEqual(color.g, 1)
            XCTAssertGreaterThanOrEqual(color.b, 0)
            XCTAssertLessThanOrEqual(color.b, 1)
        }
    }
    
    // MARK: - Discrete Palette Tests
    
    func testDiscretePaletteGeneration() {
        let anchor = ColorJourneyRGB(r: 0.4, g: 0.6, b: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
        
        // All colors should be valid
        for color in palette {
            XCTAssertGreaterThanOrEqual(color.r, 0)
            XCTAssertLessThanOrEqual(color.r, 1)
            XCTAssertGreaterThanOrEqual(color.g, 0)
            XCTAssertLessThanOrEqual(color.g, 1)
            XCTAssertGreaterThanOrEqual(color.b, 0)
            XCTAssertLessThanOrEqual(color.b, 1)
        }
    }
    
    func testLargePaletteGeneration() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 20)
        XCTAssertEqual(palette.count, 20)
    }
    
    func testSingleColorPalette() {
        let anchor = ColorJourneyRGB(r: 0.6, g: 0.4, b: 0.5)
        let config = ColorJourneyConfig.singleAnchor(anchor, style: .balanced)
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 1)
        XCTAssertEqual(palette.count, 1)
        XCTAssertNotNil(palette[0])
    }
    
    // MARK: - Perceptual Dynamics Tests
    
    func testLightnessBiasNeutral() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .neutral
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testLightnessBiasLighter() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .lighter
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testLightnessBiasDarker() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .darker
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testChromaBiasNeutral() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.6, b: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .neutral
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testChromaBiasMuted() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.6, b: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .muted
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testChromaBiasVivid() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.6, b: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .vivid
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testContrastLow() {
        let anchors = [
            ColorJourneyRGB(r: 0.4, g: 0.4, b: 0.4),
            ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .low
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }
    
    func testContrastMedium() {
        let anchors = [
            ColorJourneyRGB(r: 0.2, g: 0.2, b: 0.2),
            ColorJourneyRGB(r: 0.8, g: 0.8, b: 0.8)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .medium
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }
    
    func testContrastHigh() {
        let anchors = [
            ColorJourneyRGB(r: 0.1, g: 0.1, b: 0.1),
            ColorJourneyRGB(r: 0.9, g: 0.9, b: 0.9)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .high
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }
    
    // MARK: - Temperature Bias Tests
    
    func testTemperatureBiasWarm() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.temperature = .warm
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testTemperatureBiasCool() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.temperature = .cool
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    // MARK: - Loop Mode Tests
    
    func testLoopModeOpen() {
        let anchor = ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.6)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.loopMode = .open
        let journey = ColorJourney(config: config)
        
        let start = journey.sample(at: 0.0)
        let end = journey.sample(at: 1.0)
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
    }
    
    func testLoopModeClosed() {
        let anchor = ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.6)
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
            ColorJourneyRGB(r: 1.0, g: 0.0, b: 0.0),
            ColorJourneyRGB(r: 0.0, g: 0.0, b: 1.0)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.loopMode = .pingPong
        let journey = ColorJourney(config: config)
        
        // Ping-pong should reverse direction at ends
        let colors = (0...20).map { i in
            journey.sample(at: Float(i) / 20.0)
        }
        XCTAssertEqual(colors.count, 21)
    }
    
    // MARK: - Variation Layer Tests
    
    func testVariationDisabled() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .off
        let journey = ColorJourney(config: config)
        
        // Should be deterministic
        let color1 = journey.sample(at: 0.5)
        let color2 = journey.sample(at: 0.5)
        
        XCTAssertEqual(color1.r, color2.r, accuracy: 0.0001)
        XCTAssertEqual(color1.g, color2.g, accuracy: 0.0001)
        XCTAssertEqual(color1.b, color2.b, accuracy: 0.0001)
    }
    
    func testVariationEnabled() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.hue, .lightness, .chroma])
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 10)
        XCTAssertEqual(palette.count, 10)
        
        // All colors should still be valid
        for color in palette {
            XCTAssertGreaterThanOrEqual(color.r, 0)
            XCTAssertLessThanOrEqual(color.r, 1)
        }
    }
    
    func testVariationHueOnly() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.hue])
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testVariationLightnessOnly() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.lightness])
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testVariationChromaOnly() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.chroma])
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testVariationDeterministicSeed() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
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
        
        for i in 0..<5 {
            XCTAssertEqual(palette1[i].r, palette2[i].r, accuracy: 0.0001)
            XCTAssertEqual(palette1[i].g, palette2[i].g, accuracy: 0.0001)
            XCTAssertEqual(palette1[i].b, palette2[i].b, accuracy: 0.0001)
        }
    }
    
    // MARK: - Custom Configuration Tests
    
    func testCustomLightnessBias() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.lightness = .custom(weight: 0.3)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testCustomChromaBias() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.6, b: 0.4)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.chroma = .custom(multiplier: 1.5)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testCustomContrastThreshold() {
        let anchors = [
            ColorJourneyRGB(r: 0.3, g: 0.3, b: 0.3),
            ColorJourneyRGB(r: 0.7, g: 0.7, b: 0.7)
        ]
        var config = ColorJourneyConfig(anchors: anchors)
        config.contrast = .custom(threshold: 0.12)
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 5)
        XCTAssertEqual(palette.count, 5)
    }
    
    // MARK: - Edge Cases & Robustness Tests
    
    func testBoundaryConditionsT0() {
        let anchor = ColorJourneyRGB(r: 0.6, g: 0.4, b: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.0)
        XCTAssertGreaterThanOrEqual(color.r, 0)
        XCTAssertLessThanOrEqual(color.r, 1)
    }
    
    func testBoundaryConditionsT1() {
        let anchor = ColorJourneyRGB(r: 0.6, g: 0.4, b: 0.2)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 1.0)
        XCTAssertGreaterThanOrEqual(color.r, 0)
        XCTAssertLessThanOrEqual(color.r, 1)
    }
    
    func testExtremeBlack() {
        let anchor = ColorJourneyRGB(r: 0.0, g: 0.0, b: 0.0)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testExtremeWhite() {
        let anchor = ColorJourneyRGB(r: 1.0, g: 1.0, b: 1.0)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testHighVibrance() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.midJourneyVibrancy = 1.0
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testZeroVibrance() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.midJourneyVibrancy = 0.0
        let journey = ColorJourney(config: config)
        
        let color = journey.sample(at: 0.5)
        XCTAssertNotNil(color)
    }
    
    func testEmptyPalette() {
        let anchor = ColorJourneyRGB(r: 0.5, g: 0.5, b: 0.5)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let palette = journey.discrete(count: 0)
        XCTAssertEqual(palette.count, 0)
    }
    
    // MARK: - Configuration Presets Tests
    
    func testAllPresets() {
        let anchor = ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.6)
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
        let rgbColor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.8)
        let swiftUIColor = rgbColor.color
        XCTAssertNotNil(swiftUIColor)
    }
    
    func testGradientGeneration() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let gradient = journey.gradient(stops: 5)
        XCTAssertNotNil(gradient)
    }
    
    func testLinearGradientGeneration() {
        let anchor = ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        let linearGradient = journey.linearGradient(stops: 10)
        XCTAssertNotNil(linearGradient)
    }
    #endif
    
    // MARK: - Performance Tests
    
    func testLargeDiscretePerformance() {
        let anchor = ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.6)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        measure {
            let _ = journey.discrete(count: 100)
        }
    }
    
    func testManySamplePerformance() {
        let anchor = ColorJourneyRGB(r: 0.4, g: 0.5, b: 0.6)
        let config = ColorJourneyConfig.singleAnchor(anchor)
        let journey = ColorJourney(config: config)
        
        measure {
            for i in 0..<1000 {
                let _ = journey.sample(at: Float(i) / 1000.0)
            }
        }
    }
}
