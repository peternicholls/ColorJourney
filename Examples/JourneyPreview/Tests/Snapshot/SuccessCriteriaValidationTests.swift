import XCTest
@testable import JourneyPreview
import ColorJourney
import Foundation

/// Success criteria validation harness for JourneyPreview demo app.
///
/// Validates the measurable outcomes defined in the feature specification:
/// - SC-001: Timing (palette generation within 15 seconds, typically <100ms)
/// - SC-002: Copy success (90% first-try success with confirmation)
/// - SC-003: Responsiveness (<1 second UI updates for large palettes)
/// - SC-004: UX satisfaction (clarity of controls, messaging, readability)
/// - SC-005: Input validation (zero crashes, safe range enforcement)
final class SuccessCriteriaValidationTests: XCTestCase {
    
    // MARK: - SC-001: Timing Tests
    
    /// SC-001: Palette generation should complete in under 15 seconds.
    /// In practice, the C core generates colors in <1ms; this validates the upper bound.
    func testSC001_paletteGenerationWithin15Seconds() {
        let startTime = Date()
        
        // Generate a moderate palette
        let journey = ColorJourney(
            config: .singleAnchor(
                ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
                style: .balanced
            )
        )
        
        let _ = journey.discrete(count: 50)
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 15.0, "Palette generation should complete in under 15 seconds")
        
        // Also verify it's actually fast (sub-second)
        XCTAssertLessThan(elapsed, 1.0, "Palette generation should be sub-second")
    }
    
    /// SC-001: Large palettes (100 colors) should still generate quickly.
    func testSC001_largePaletteGenerationTiming() {
        let startTime = Date()
        
        let journey = ColorJourney(
            config: .singleAnchor(
                ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.4),
                style: .vividLoop
            )
        )
        
        let _ = journey.discrete(count: 100)
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 15.0, "Large palette should complete in under 15 seconds")
        XCTAssertLessThan(elapsed, 1.0, "Large palette should be sub-second")
    }
    
    /// SC-001: Maximum palette (200 colors) timing validation.
    func testSC001_maximumPaletteGenerationTiming() {
        let startTime = Date()
        
        let journey = ColorJourney(
            config: .singleAnchor(
                ColorJourneyRGB(red: 0.7, green: 0.2, blue: 0.5),
                style: .balanced
            )
        )
        
        let _ = journey.discrete(count: 200)
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 15.0, "Maximum palette should complete in under 15 seconds")
        XCTAssertLessThan(elapsed, 1.0, "Maximum palette should be sub-second")
    }
    
    // MARK: - SC-002: Copy Success Tests
    
    /// SC-002: Code snippet generation produces valid, copyable content.
    func testSC002_swiftCodeSnippetGeneration() {
        let colors = [
            ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)
        ]
        
        let snippet = CodeGenerator.generateSwiftColors(colors: colors)
        
        // Verify non-empty content
        XCTAssertFalse(snippet.isEmpty, "Swift code snippet should not be empty")
        
        // Verify it contains expected Swift syntax
        XCTAssertTrue(snippet.contains("ColorJourneyRGB"), "Should contain ColorJourneyRGB type")
        XCTAssertTrue(snippet.contains("let"), "Should contain let keyword")
    }
    
    /// SC-002: CSS snippet generation produces valid content.
    func testSC002_cssSnippetGeneration() {
        let colors = [
            ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        ]
        
        let snippet = CodeGenerator.generateCSS(colors: colors)
        
        XCTAssertFalse(snippet.isEmpty, "CSS snippet should not be empty")
        XCTAssertTrue(snippet.contains(".color-"), "Should contain CSS class selector")
        XCTAssertTrue(snippet.contains("#"), "Should contain hex color")
    }
    
    /// SC-002: CSS variables snippet generation produces valid content.
    func testSC002_cssVariablesSnippetGeneration() {
        let colors = [
            ColorJourneyRGB(red: 0.25, green: 0.75, blue: 0.5)
        ]
        
        let snippet = CodeGenerator.generateCSSVariables(colors: colors)
        
        XCTAssertFalse(snippet.isEmpty, "CSS variables snippet should not be empty")
        XCTAssertTrue(snippet.contains(":root"), "Should contain :root selector")
        XCTAssertTrue(snippet.contains("--palette-color-"), "Should contain CSS custom property")
    }
    
    /// SC-002: Copy state transitions work correctly.
    func testSC002_copyStateTransitions() {
        // Verify state transitions
        let idle = CopyState.idle
        XCTAssertFalse(idle.isCopying, "Idle state should not be copying")
        XCTAssertFalse(idle.isSuccess, "Idle state should not be success")
        
        let copying = CopyState.copying
        XCTAssertTrue(copying.isCopying, "Copying state should be copying")
        
        let success = CopyState.success
        XCTAssertTrue(success.isSuccess, "Success state should be success")
        
        let failed = CopyState.failed("Test error")
        XCTAssertFalse(failed.isSuccess, "Failed state should not be success")
    }
    
    // MARK: - SC-003: Responsiveness Tests
    
    /// SC-003: Large palette requests should include advisory messaging.
    func testSC003_largePaletteAdvisoryMessaging() {
        // 75 colors - should get advisory
        let advisoryResult = InputValidation.validatePaletteCount(75)
        if case .advisory(let message, let value) = advisoryResult {
            XCTAssertEqual(value, 75)
            XCTAssertFalse(message.isEmpty, "Advisory message should not be empty")
        } else {
            XCTFail("Expected advisory result for 75 colors")
        }
        
        // 150 colors - should get warning
        let warningResult = InputValidation.validatePaletteCount(150)
        if case .warning(let message, let value) = warningResult {
            XCTAssertEqual(value, 150)
            XCTAssertFalse(message.isEmpty, "Warning message should not be empty")
        } else {
            XCTFail("Expected warning result for 150 colors")
        }
    }
    
    /// SC-003: UI responsiveness - palette generation plus display conversion under 1 second.
    func testSC003_uiResponsiveness() {
        let startTime = Date()
        
        // Simulate full UI workflow: generate + convert to display
        let journey = ColorJourney(
            config: .singleAnchor(
                ColorJourneyRGB(red: 0.4, green: 0.4, blue: 0.6),
                style: .balanced
            )
        )
        
        let colors = journey.discrete(count: 100)
        let swatches = SwatchDisplay.fromPalette(colors, size: .medium, showLabels: true)
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(swatches.count, 100)
        XCTAssertLessThan(elapsed, 1.0, "Full workflow should complete in under 1 second")
    }
    
    // MARK: - SC-004: UX Clarity Tests
    
    /// SC-004: Swatch display provides readable hex strings.
    func testSC004_swatchReadability() {
        let colors = [
            ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0),
            ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)
        ]
        
        let swatches = SwatchDisplay.fromPalette(colors, size: .large, showLabels: true)
        
        XCTAssertEqual(swatches[0].hexString, "#FF0000", "Red should be #FF0000")
        XCTAssertEqual(swatches[1].hexString, "#00FF00", "Green should be #00FF00")
        XCTAssertEqual(swatches[2].hexString, "#0000FF", "Blue should be #0000FF")
    }
    
    /// SC-004: Text contrast is appropriate for backgrounds.
    func testSC004_textContrastAdaptation() {
        // Light swatch should prefer dark text
        let lightSwatch = SwatchDisplay(
            index: 0,
            color: ColorJourneyRGB(red: 0.95, green: 0.95, blue: 0.95),
            size: .medium
        )
        XCTAssertTrue(lightSwatch.prefersDarkText, "Light swatches should prefer dark text")
        
        // Dark swatch should prefer light text
        let darkSwatch = SwatchDisplay(
            index: 0,
            color: ColorJourneyRGB(red: 0.05, green: 0.05, blue: 0.05),
            size: .medium
        )
        XCTAssertFalse(darkSwatch.prefersDarkText, "Dark swatches should prefer light text")
    }
    
    /// SC-004: Advisory types provide meaningful icons.
    func testSC004_advisoryTypesHaveMeaningfulIcons() {
        XCTAssertEqual(AdvisoryType.info.iconName, "info.circle.fill")
        XCTAssertEqual(AdvisoryType.warning.iconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(AdvisoryType.error.iconName, "xmark.octagon.fill")
        XCTAssertEqual(AdvisoryType.success.iconName, "checkmark.circle.fill")
        XCTAssertEqual(AdvisoryType.performance.iconName, "gauge.with.needle.fill")
    }
    
    /// SC-004: Swatch sizes have appropriate corner radii.
    func testSC004_swatchSizesHaveAppropriateStyling() {
        // Corner radii should scale with size
        XCTAssertEqual(SwatchSizePreference.small.cornerRadius, 8)
        XCTAssertEqual(SwatchSizePreference.medium.cornerRadius, 12)
        XCTAssertEqual(SwatchSizePreference.large.cornerRadius, 16)
        XCTAssertEqual(SwatchSizePreference.extraLarge.cornerRadius, 20)
        
        // Dimensions should increase
        XCTAssertLessThan(SwatchSizePreference.small.pointSize, SwatchSizePreference.medium.pointSize)
        XCTAssertLessThan(SwatchSizePreference.medium.pointSize, SwatchSizePreference.large.pointSize)
        XCTAssertLessThan(SwatchSizePreference.large.pointSize, SwatchSizePreference.extraLarge.pointSize)
    }
    
    // MARK: - SC-005: Input Validation Tests
    
    /// SC-005: Invalid palette counts are rejected without crash.
    func testSC005_invalidPaletteCountRejection() {
        // Negative
        let negativeResult = InputValidation.validatePaletteCount(-5)
        XCTAssertFalse(negativeResult.isValid, "Negative count should be invalid")
        
        // Zero
        let zeroResult = InputValidation.validatePaletteCount(0)
        XCTAssertFalse(zeroResult.isValid, "Zero count should be invalid")
        
        // Over maximum
        let overMaxResult = InputValidation.validatePaletteCount(300)
        XCTAssertFalse(overMaxResult.isValid, "Over-max count should be invalid")
    }
    
    /// SC-005: Valid palette counts are accepted.
    func testSC005_validPaletteCountAcceptance() {
        // Minimum
        let minResult = InputValidation.validatePaletteCount(1)
        XCTAssertTrue(minResult.isValid, "Minimum count (1) should be valid")
        
        // Typical
        let typicalResult = InputValidation.validatePaletteCount(12)
        XCTAssertTrue(typicalResult.isValid, "Typical count (12) should be valid")
        
        // Threshold boundary
        let thresholdResult = InputValidation.validatePaletteCount(50)
        XCTAssertTrue(thresholdResult.isValid, "Threshold count (50) should be valid")
        
        // Maximum
        let maxResult = InputValidation.validatePaletteCount(200)
        XCTAssertTrue(maxResult.isValid, "Maximum count (200) should be valid")
    }
    
    /// SC-005: Clamp function enforces safe ranges.
    func testSC005_clampFunctionEnforcesSafeRanges() {
        XCTAssertEqual(InputValidation.clampPaletteCount(-100), 1, "Should clamp negative to 1")
        XCTAssertEqual(InputValidation.clampPaletteCount(0), 1, "Should clamp zero to 1")
        XCTAssertEqual(InputValidation.clampPaletteCount(50), 50, "Should keep valid values unchanged")
        XCTAssertEqual(InputValidation.clampPaletteCount(500), 200, "Should clamp over-max to 200")
    }
    
    /// SC-005: Hex color validation handles edge cases.
    func testSC005_hexColorValidation() {
        // Valid formats
        XCTAssertTrue(InputValidation.validateHexColor("#FF5500").isValid)
        XCTAssertTrue(InputValidation.validateHexColor("FF5500").isValid)
        XCTAssertTrue(InputValidation.validateHexColor("ff5500").isValid)
        
        // Invalid formats
        XCTAssertFalse(InputValidation.validateHexColor("FFF").isValid, "3-digit hex should be invalid")
        XCTAssertFalse(InputValidation.validateHexColor("GGHHII").isValid, "Invalid chars should be invalid")
        XCTAssertFalse(InputValidation.validateHexColor("").isValid, "Empty should be invalid")
    }
    
    /// SC-005: RGB component validation handles edge cases.
    func testSC005_rgbComponentValidation() {
        // Valid range
        XCTAssertTrue(InputValidation.validateRGBComponent(0).isValid)
        XCTAssertTrue(InputValidation.validateRGBComponent(128).isValid)
        XCTAssertTrue(InputValidation.validateRGBComponent(255).isValid)
        
        // Invalid range
        XCTAssertFalse(InputValidation.validateRGBComponent(-1).isValid)
        XCTAssertFalse(InputValidation.validateRGBComponent(256).isValid)
        XCTAssertFalse(InputValidation.validateRGBComponent(1000).isValid)
    }
    
    /// SC-005: Float RGB validation handles edge cases.
    func testSC005_floatRGBComponentValidation() {
        XCTAssertTrue(InputValidation.validateFloatRGBComponent(0.0))
        XCTAssertTrue(InputValidation.validateFloatRGBComponent(0.5))
        XCTAssertTrue(InputValidation.validateFloatRGBComponent(1.0))
        
        XCTAssertFalse(InputValidation.validateFloatRGBComponent(-0.001))
        XCTAssertFalse(InputValidation.validateFloatRGBComponent(1.001))
    }
    
    // MARK: - Request Limits Tests
    
    /// Verify request limits are correctly defined.
    func testRequestLimitsConstants() {
        XCTAssertEqual(RequestLimits.warningThreshold, 50)
        XCTAssertEqual(RequestLimits.recommendedMaximum, 100)
        XCTAssertEqual(RequestLimits.absoluteMaximum, 200)
    }
    
    // MARK: - ColorSetRequest Tests
    
    /// SC-005: ColorSetRequest validates its contents.
    func testColorSetRequestValidation() {
        // Valid request
        let validRequest = ColorSetRequest(count: 25)
        XCTAssertTrue(validRequest.isValid)
        XCTAssertTrue(validRequest.validationErrors.isEmpty)
        
        // Invalid - too low
        let lowRequest = ColorSetRequest(count: 0)
        XCTAssertFalse(lowRequest.isValid)
        XCTAssertTrue(lowRequest.validationErrors.contains(.countTooLow))
        
        // Invalid - too high
        let highRequest = ColorSetRequest(count: 500)
        XCTAssertFalse(highRequest.isValid)
        XCTAssertTrue(highRequest.validationErrors.contains(.countExceedsMaximum))
    }
    
    /// Test warning threshold detection.
    func testWarningThresholdDetection() {
        let belowThreshold = ColorSetRequest(count: 49)
        XCTAssertFalse(belowThreshold.exceedsWarningThreshold)
        
        let atThreshold = ColorSetRequest(count: 50)
        XCTAssertFalse(atThreshold.exceedsWarningThreshold)
        
        let aboveThreshold = ColorSetRequest(count: 51)
        XCTAssertTrue(aboveThreshold.exceedsWarningThreshold)
    }
}
