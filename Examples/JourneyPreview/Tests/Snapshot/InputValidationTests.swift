import XCTest
@testable import JourneyPreview
import ColorJourney

/// Tests for input validation utilities.
final class InputValidationTests: XCTestCase {
    
    // MARK: - Palette Count Validation
    
    func testValidPaletteCount() {
        let result = InputValidation.validatePaletteCount(25)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.value, 25)
        XCTAssertNil(result.message)
    }
    
    func testPaletteCountTooLow() {
        let result = InputValidation.validatePaletteCount(0)
        
        XCTAssertFalse(result.isValid)
        if case .invalid(let error, _) = result {
            XCTAssertTrue(error.contains("at least 1"))
        } else {
            XCTFail("Expected invalid result")
        }
    }
    
    func testPaletteCountTooHigh() {
        let result = InputValidation.validatePaletteCount(300)
        
        XCTAssertFalse(result.isValid)
        if case .invalid(let error, _) = result {
            XCTAssertTrue(error.contains("exceed"))
        } else {
            XCTFail("Expected invalid result")
        }
    }
    
    func testPaletteCountWithWarning() {
        let result = InputValidation.validatePaletteCount(150)
        
        XCTAssertTrue(result.isValid)
        if case .warning(let message, let value) = result {
            XCTAssertTrue(message.contains("performance"))
            XCTAssertEqual(value, 150)
        } else {
            XCTFail("Expected warning result")
        }
    }
    
    func testPaletteCountWithAdvisory() {
        let result = InputValidation.validatePaletteCount(75)
        
        XCTAssertTrue(result.isValid)
        if case .advisory(let message, let value) = result {
            XCTAssertTrue(message.contains("grouped"))
            XCTAssertEqual(value, 75)
        } else {
            XCTFail("Expected advisory result")
        }
    }
    
    func testClampPaletteCount() {
        XCTAssertEqual(InputValidation.clampPaletteCount(-5), 1)
        XCTAssertEqual(InputValidation.clampPaletteCount(0), 1)
        XCTAssertEqual(InputValidation.clampPaletteCount(50), 50)
        XCTAssertEqual(InputValidation.clampPaletteCount(300), 200)
    }
    
    // MARK: - Numeric Input Parsing
    
    func testParseValidNumericInput() {
        let result = InputValidation.parseNumericInput("42", range: 1...100)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.value, 42)
    }
    
    func testParseNumericInputWithWhitespace() {
        let result = InputValidation.parseNumericInput("  42  ", range: 1...100)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.value, 42)
    }
    
    func testParseInvalidNumericInput() {
        let result = InputValidation.parseNumericInput("abc", range: 1...100)
        
        XCTAssertFalse(result.isValid)
    }
    
    func testParseNumericInputBelowRange() {
        let result = InputValidation.parseNumericInput("0", range: 1...100)
        
        XCTAssertFalse(result.isValid)
    }
    
    func testParseNumericInputAboveRange() {
        let result = InputValidation.parseNumericInput("200", range: 1...100)
        
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Hex Color Validation
    
    func testValidHexColor() {
        let result = InputValidation.validateHexColor("#FF5500")
        
        XCTAssertTrue(result.isValid)
        if let color = result.color {
            XCTAssertEqual(color.red, 1.0, accuracy: 0.01)
            XCTAssertEqual(color.green, 0.333, accuracy: 0.01)
            XCTAssertEqual(color.blue, 0.0, accuracy: 0.01)
        }
    }
    
    func testValidHexColorWithoutHash() {
        let result = InputValidation.validateHexColor("FF5500")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testValidHexColorLowercase() {
        let result = InputValidation.validateHexColor("ff5500")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testInvalidHexColorTooShort() {
        let result = InputValidation.validateHexColor("FFF")
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.error?.contains("6 characters") ?? false)
    }
    
    func testInvalidHexColorBadCharacters() {
        let result = InputValidation.validateHexColor("GGHHII")
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.error?.contains("Invalid hex") ?? false)
    }
    
    // MARK: - RGB Component Validation
    
    func testValidRGBComponent() {
        let result = InputValidation.validateRGBComponent(128)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.value, 128)
    }
    
    func testRGBComponentNegative() {
        let result = InputValidation.validateRGBComponent(-10)
        
        XCTAssertFalse(result.isValid)
    }
    
    func testRGBComponentTooHigh() {
        let result = InputValidation.validateRGBComponent(300)
        
        XCTAssertFalse(result.isValid)
    }
    
    func testValidFloatRGBComponent() {
        XCTAssertTrue(InputValidation.validateFloatRGBComponent(0.0))
        XCTAssertTrue(InputValidation.validateFloatRGBComponent(0.5))
        XCTAssertTrue(InputValidation.validateFloatRGBComponent(1.0))
        XCTAssertFalse(InputValidation.validateFloatRGBComponent(-0.1))
        XCTAssertFalse(InputValidation.validateFloatRGBComponent(1.1))
    }
}
