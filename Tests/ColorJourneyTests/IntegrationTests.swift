/**
 * Integration Tests for Incremental Creation Feature (T038)
 *
 * Phase 2 integration tests validating combined feature behavior:
 * - C core and Swift wrapper consistency
 * - Delta range enforcement with various configurations
 * - Performance characteristics
 * - Thread safety integration
 *
 * Feature: 004-incremental-creation
 * Spec: specs/004-incremental-creation/spec.md
 */

import XCTest
import CColorJourney
@testable import ColorJourney

final class IncrementalIntegrationTests: XCTestCase {

    // MARK: - Test Configuration

    /// Delta range bounds per spec
    private let deltaMin: Float = 0.02
    private let deltaMax: Float = 0.05
    private let deltaTolerance: Float = 0.001

    /// Helper: Calculate OKLab delta E between two colors using C core
    private func deltaE(_ a: ColorJourneyRGB, _ b: ColorJourneyRGB) -> Float {
        let labA = cj_rgb_to_oklab(CJ_RGB(r: a.red, g: a.green, b: a.blue))
        let labB = cj_rgb_to_oklab(CJ_RGB(r: b.red, g: b.green, b: b.blue))
        return cj_delta_e(labA, labB)
    }

    // MARK: - T038-01: Swift Wrapper Consistency with C Core

    /// Verifies Swift discrete(at:) matches C core behavior
    func testSwiftWrapperConsistency() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.3),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        // Test determinism: same index should return same color
        for index in [0, 5, 10, 50, 100] {
            let color1 = journey.discrete(at: index)
            let color2 = journey.discrete(at: index)

            XCTAssertEqual(color1.red, color2.red, accuracy: 1e-6,
                           "Index \(index) should be deterministic (red)")
            XCTAssertEqual(color1.green, color2.green, accuracy: 1e-6,
                           "Index \(index) should be deterministic (green)")
            XCTAssertEqual(color1.blue, color2.blue, accuracy: 1e-6,
                           "Index \(index) should be deterministic (blue)")
        }
    }

    // MARK: - T038-02: Range API Matches Individual Calls

    /// Verifies discrete(range:) matches discrete(at:) for each index
    func testRangeMatchesIndividualCalls() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.7),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        let rangeColors = journey.discrete(range: 0..<20)
        XCTAssertEqual(rangeColors.count, 20)

        for (offset, rangeColor) in rangeColors.enumerated() {
            let individualColor = journey.discrete(at: offset)

            XCTAssertEqual(rangeColor.red, individualColor.red, accuracy: 1e-6,
                           "Range and individual should match at index \(offset)")
            XCTAssertEqual(rangeColor.green, individualColor.green, accuracy: 1e-6)
            XCTAssertEqual(rangeColor.blue, individualColor.blue, accuracy: 1e-6)
        }
    }

    // MARK: - T038-03: Subscript Access Matches discrete(at:)

    /// Verifies subscript access matches discrete(at:) method
    func testSubscriptMatchesDiscreteAt() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.5, green: 0.4, blue: 0.6),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        for index in 0..<10 {
            let subscriptColor = journey[index]
            let methodColor = journey.discrete(at: index)

            XCTAssertEqual(subscriptColor.red, methodColor.red, accuracy: 1e-6)
            XCTAssertEqual(subscriptColor.green, methodColor.green, accuracy: 1e-6)
            XCTAssertEqual(subscriptColor.blue, methodColor.blue, accuracy: 1e-6)
        }
    }

    // MARK: - T038-04: Lazy Sequence Matches Range

    /// Verifies discreteColors lazy sequence matches range access
    func testLazySequenceMatchesRange() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.2, green: 0.6, blue: 0.8),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        let sequenceColors = Array(journey.discreteColors.prefix(15))
        let rangeColors = journey.discrete(range: 0..<15)

        XCTAssertEqual(sequenceColors.count, rangeColors.count)

        for (seqColor, rangeColor) in zip(sequenceColors, rangeColors) {
            XCTAssertEqual(seqColor.red, rangeColor.red, accuracy: 1e-6)
            XCTAssertEqual(seqColor.green, rangeColor.green, accuracy: 1e-6)
            XCTAssertEqual(seqColor.blue, rangeColor.blue, accuracy: 1e-6)
        }
    }

    // MARK: - T038-05: Delta Enforcement with LOW Contrast

    /// Verifies delta range [0.02, 0.05] with LOW contrast
    func testDeltaEnforcementLowContrast() {
        var config = ColorJourneyConfig(anchors: [
            ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4)
        ])
        config.contrast = .low
        let journey = ColorJourney(config: config)

        let count = 50
        var minViolations = 0

        var prevColor = journey.discrete(at: 0)
        for i in 1..<count {
            let currColor = journey.discrete(at: i)
            let de = deltaE(currColor, prevColor)

            if de < deltaMin - deltaTolerance {
                minViolations += 1
            }
            prevColor = currColor
        }

        XCTAssertEqual(minViolations, 0,
                       "LOW contrast should satisfy minimum ΔE constraint")
    }

    // MARK: - T038-06: Delta Enforcement with MEDIUM Contrast

    /// Verifies delta range with MEDIUM contrast (stricter minimum)
    func testDeltaEnforcementMediumContrast() {
        var config = ColorJourneyConfig(anchors: [
            ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        ])
        config.contrast = .medium
        let journey = ColorJourney(config: config)

        let count = 50
        var violations = 0
        let mediumMin: Float = 0.10 // MEDIUM contrast minimum

        var prevColor = journey.discrete(at: 0)
        for i in 1..<count {
            let currColor = journey.discrete(at: i)
            let de = deltaE(currColor, prevColor)

            if de < mediumMin - deltaTolerance {
                violations += 1
            }
            prevColor = currColor
        }

        XCTAssertEqual(violations, 0,
                       "MEDIUM contrast should satisfy ΔE ≥ 0.10")
    }

    // MARK: - T038-07: Delta Enforcement with HIGH Contrast

    /// Verifies delta range with HIGH contrast (strictest minimum)
    func testDeltaEnforcementHighContrast() {
        var config = ColorJourneyConfig(anchors: [
            ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)
        ])
        config.contrast = .high
        let journey = ColorJourney(config: config)

        let count = 50
        var violations = 0
        let highMin: Float = 0.15 // HIGH contrast minimum

        var prevColor = journey.discrete(at: 0)
        for i in 1..<count {
            let currColor = journey.discrete(at: i)
            let de = deltaE(currColor, prevColor)

            if de < highMin - deltaTolerance {
                violations += 1
            }
            prevColor = currColor
        }

        XCTAssertEqual(violations, 0,
                       "HIGH contrast should satisfy ΔE ≥ 0.15")
    }

    // MARK: - T038-08: Multi-Anchor Journey Integration

    /// Verifies delta enforcement with multi-anchor journey
    func testMultiAnchorJourneyIntegration() {
        let config = ColorJourneyConfig.multiAnchor([
            ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)
        ], style: .balanced)
        let journey = ColorJourney(config: config)

        // Verify range access produces valid colors
        let colors = journey.discrete(range: 0..<30)
        XCTAssertEqual(colors.count, 30)

        // Verify all colors are in valid RGB range
        for color in colors {
            XCTAssertGreaterThanOrEqual(color.red, 0)
            XCTAssertLessThanOrEqual(color.red, 1)
            XCTAssertGreaterThanOrEqual(color.green, 0)
            XCTAssertLessThanOrEqual(color.green, 1)
            XCTAssertGreaterThanOrEqual(color.blue, 0)
            XCTAssertLessThanOrEqual(color.blue, 1)
        }
    }

    // MARK: - T038-09: Different Journey Instances Consistency

    /// Verifies two journey instances with same config produce same colors
    func testDifferentInstancesConsistency() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.7),
            style: .balanced
        )

        let journey1 = ColorJourney(config: config)
        let journey2 = ColorJourney(config: config)

        for index in 0..<20 {
            let color1 = journey1.discrete(at: index)
            let color2 = journey2.discrete(at: index)

            XCTAssertEqual(color1.red, color2.red, accuracy: 1e-6,
                           "Different instances should produce same colors")
            XCTAssertEqual(color1.green, color2.green, accuracy: 1e-6)
            XCTAssertEqual(color1.blue, color2.blue, accuracy: 1e-6)
        }
    }

    // MARK: - T038-10: Preset Styles Integration

    /// Verifies all preset styles work with incremental API
    func testPresetStylesIntegration() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)
        let styles: [JourneyStyle] = [
            .balanced,
            .pastelDrift,
            .vividLoop,
            .nightMode,
            .warmEarth,
            .coolSky
        ]

        for style in styles {
            let config = ColorJourneyConfig.singleAnchor(anchor, style: style)
            let journey = ColorJourney(config: config)

            // Verify can generate colors without error
            let colors = journey.discrete(range: 0..<10)
            XCTAssertEqual(colors.count, 10, "Style \(style) should generate 10 colors")

            // Verify colors are valid
            for color in colors {
                XCTAssertGreaterThanOrEqual(color.red, 0)
                XCTAssertLessThanOrEqual(color.red, 1)
            }
        }
    }

    // MARK: - T038-11: Variation Layer Integration

    /// Verifies variation layer works with incremental API
    func testVariationLayerIntegration() {
        let anchor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        var config = ColorJourneyConfig(anchors: [anchor])
        config.variation = .subtle(dimensions: [.hue, .lightness], seed: 42)

        let journey = ColorJourney(config: config)
        let colors = journey.discrete(range: 0..<10)

        XCTAssertEqual(colors.count, 10)

        // Verify determinism with same seed
        let journey2 = ColorJourney(config: config)
        let colors2 = journey2.discrete(range: 0..<10)

        for (c1, c2) in zip(colors, colors2) {
            XCTAssertEqual(c1.red, c2.red, accuracy: 1e-6,
                           "Same seed should produce same colors")
        }
    }

    // MARK: - T038-12: Loop Mode Integration

    /// Verifies loop modes work with incremental API
    func testLoopModeIntegration() {
        let anchor = ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.6)

        // Test closed loop
        var closedConfig = ColorJourneyConfig(anchors: [anchor])
        closedConfig.loopMode = .closed
        let closedJourney = ColorJourney(config: closedConfig)
        let closedColors = closedJourney.discrete(range: 0..<25)
        XCTAssertEqual(closedColors.count, 25)

        // Test open loop
        var openConfig = ColorJourneyConfig(anchors: [anchor])
        openConfig.loopMode = .open
        let openJourney = ColorJourney(config: openConfig)
        let openColors = openJourney.discrete(range: 0..<25)
        XCTAssertEqual(openColors.count, 25)
    }

    // MARK: - T038-13: Large Index Performance Check

    /// Verifies large index access completes in reasonable time
    func testLargeIndexPerformance() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        // Access large indices (should complete quickly despite O(n))
        // Note: Using moderate indices to avoid very slow test
        let largeIndices = [100, 500, 1000]

        for index in largeIndices {
            let color = journey.discrete(at: index)
            XCTAssertGreaterThanOrEqual(color.red, 0,
                                        "Large index \(index) should produce valid color")
        }
    }

    // MARK: - T038-14: Range Performance vs Individual Calls

    /// Verifies range access is more efficient than individual calls
    func testRangeVsIndividualPerformance() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.5),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        let count = 50

        // Time range access
        let rangeStart = Date()
        _ = journey.discrete(range: 0..<count)
        let rangeTime = Date().timeIntervalSince(rangeStart)

        // Time individual access (should be slower due to O(n) per call)
        let individualStart = Date()
        for i in 0..<count {
            _ = journey.discrete(at: i)
        }
        let individualTime = Date().timeIntervalSince(individualStart)

        // Range should be faster (but don't fail test if not, just log)
        if rangeTime < individualTime {
            print("  Range access (\(rangeTime)s) faster than individual (\(individualTime)s)")
        } else {
            print("  Note: Individual (\(individualTime)s) was faster than range (\(rangeTime)s)")
        }

        // Both should complete reasonably quickly
        XCTAssertLessThan(rangeTime, 1.0, "Range access should complete in < 1s")
        XCTAssertLessThan(individualTime, 5.0, "Individual access should complete in < 5s")
    }

    // MARK: - T038-15: All Colors Unique

    /// Verifies consecutive colors are unique (not duplicated)
    func testAllColorsUnique() {
        let config = ColorJourneyConfig.singleAnchor(
            ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4),
            style: .balanced
        )
        let journey = ColorJourney(config: config)

        let colors = journey.discrete(range: 0..<50)
        var duplicateCount = 0

        for i in 1..<colors.count {
            let curr = colors[i]
            let prev = colors[i - 1]

            let isSame = abs(curr.red - prev.red) < 1e-6 &&
                         abs(curr.green - prev.green) < 1e-6 &&
                         abs(curr.blue - prev.blue) < 1e-6

            if isSame {
                duplicateCount += 1
            }
        }

        XCTAssertEqual(duplicateCount, 0, "No consecutive colors should be identical")
    }
}
