import XCTest
@testable import JourneyPreview
import ColorJourney

/// Unit tests for model types and validation utilities.
final class ModelTests: XCTestCase {
    
    // MARK: - ColorSetRequest Tests
    
    func testDefaultColorSetRequest() {
        let request = ColorSetRequest()
        
        XCTAssertEqual(request.count, 8)
        XCTAssertEqual(request.deltaTarget, .medium)
        XCTAssertFalse(request.bypassLargeWarning)
        XCTAssertTrue(request.isValid)
    }
    
    func testColorSetRequestValidation() {
        // Valid request
        let validRequest = ColorSetRequest(count: 50)
        XCTAssertTrue(validRequest.isValid)
        XCTAssertTrue(validRequest.validationErrors.isEmpty)
        
        // Count too low
        let lowRequest = ColorSetRequest(count: 0)
        XCTAssertFalse(lowRequest.isValid)
        XCTAssertTrue(lowRequest.validationErrors.contains(.countTooLow))
        
        // Count too high
        let highRequest = ColorSetRequest(count: 300)
        XCTAssertFalse(highRequest.isValid)
        XCTAssertTrue(highRequest.validationErrors.contains(.countExceedsMaximum))
    }
    
    func testColorSetRequestWarningThreshold() {
        let belowThreshold = ColorSetRequest(count: 40)
        XCTAssertFalse(belowThreshold.exceedsWarningThreshold)
        
        let aboveThreshold = ColorSetRequest(count: 60)
        XCTAssertTrue(aboveThreshold.exceedsWarningThreshold)
    }
    
    // MARK: - SwatchDisplay Tests
    
    func testSwatchDisplayFromPalette() {
        let colors = [
            ColorJourneyRGB(red: 1, green: 0, blue: 0),
            ColorJourneyRGB(red: 0, green: 1, blue: 0),
            ColorJourneyRGB(red: 0, green: 0, blue: 1)
        ]
        
        let swatches = SwatchDisplay.fromPalette(colors, size: .large, showLabels: true)
        
        XCTAssertEqual(swatches.count, 3)
        XCTAssertEqual(swatches[0].hexString, "#FF0000")
        XCTAssertEqual(swatches[1].hexString, "#00FF00")
        XCTAssertEqual(swatches[2].hexString, "#0000FF")
        XCTAssertEqual(swatches[0].size, .large)
        XCTAssertEqual(swatches[0].label, "0")
    }
    
    func testRelativeLuminance() {
        // Black
        let black = SwatchDisplay(index: 0, color: ColorJourneyRGB(red: 0, green: 0, blue: 0), size: .medium)
        XCTAssertEqual(black.relativeLuminance, 0, accuracy: 0.001)
        
        // White
        let white = SwatchDisplay(index: 0, color: ColorJourneyRGB(red: 1, green: 1, blue: 1), size: .medium)
        XCTAssertEqual(white.relativeLuminance, 1, accuracy: 0.001)
        
        // Gray
        let gray = SwatchDisplay(index: 0, color: ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5), size: .medium)
        XCTAssertEqual(gray.relativeLuminance, 0.5, accuracy: 0.001)
    }
    
    // MARK: - CodeSnippet Tests
    
    func testCodeSnippetTypes() {
        XCTAssertEqual(SnippetType.swiftUsage.language, "swift")
        XCTAssertEqual(SnippetType.css.language, "css")
        XCTAssertEqual(SnippetType.cssVariables.fileExtension, "css")
    }
    
    func testCopyState() {
        XCTAssertFalse(CopyState.idle.isCopying)
        XCTAssertTrue(CopyState.copying.isCopying)
        XCTAssertTrue(CopyState.success.isSuccess)
        XCTAssertFalse(CopyState.failed("error").isSuccess)
    }
    
    // MARK: - CodeGenerator Tests
    
    func testGenerateSwiftColors() {
        let colors = [
            ColorJourneyRGB(red: 0.5, green: 0.25, blue: 0.75)
        ]
        
        let code = CodeGenerator.generateSwiftColors(colors: colors)
        
        XCTAssertTrue(code.contains("ColorJourneyRGB"))
        XCTAssertTrue(code.contains("0.500"))
        XCTAssertTrue(code.contains("0.250"))
        XCTAssertTrue(code.contains("0.750"))
    }
    
    func testGenerateCSS() {
        let colors = [
            ColorJourneyRGB(red: 1, green: 0, blue: 0),
            ColorJourneyRGB(red: 0, green: 1, blue: 0)
        ]
        
        let code = CodeGenerator.generateCSS(colors: colors)
        
        XCTAssertTrue(code.contains(".color-0"))
        XCTAssertTrue(code.contains(".color-1"))
        XCTAssertTrue(code.contains("#FF0000"))
        XCTAssertTrue(code.contains("#00FF00"))
    }
    
    func testGenerateCSSVariables() {
        let colors = [
            ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        ]
        
        let code = CodeGenerator.generateCSSVariables(colors: colors)
        
        XCTAssertTrue(code.contains(":root"))
        XCTAssertTrue(code.contains("--palette-color-0"))
        XCTAssertTrue(code.contains("#7F7F7F"))
    }
    
    // MARK: - DeltaTarget Tests
    
    func testDeltaTargetContrastLevel() {
        XCTAssertEqual(DeltaTarget.tight.contrastLevel, .low)
        XCTAssertEqual(DeltaTarget.medium.contrastLevel, .medium)
        XCTAssertEqual(DeltaTarget.wide.contrastLevel, .high)
    }
}
