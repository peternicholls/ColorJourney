# API Contract: InputValidation Utilities

**Version**: 1.0  
**Module**: Models/InputValidation.swift

## Overview

Validation utilities for user input in the JourneyPreview demo app.

## Public Interface

### ValidationResult Enum

```swift
enum ValidationResult<T: Equatable>: Equatable {
    case valid(T)
    case advisory(String, T)
    case warning(String, T)
    case invalid(String, String?)  // (error, suggestion)
}
```

### InputValidation Struct

```swift
struct InputValidation {
    static func validatePaletteCount(_ input: String) -> ValidationResult<Int>
    static func validateHexColor(_ input: String) -> ValidationResult<String>
    static func validateRGBComponent(_ input: String) -> ValidationResult<Int>
    static func clampPaletteCount(_ count: Int) -> Int
}
```

## Method Specifications

### validatePaletteCount

| Input | Result | Details |
|-------|--------|---------|
| "" | `.invalid` | "Please enter a number", nil |
| "abc" | `.invalid` | "'\(input)' is not a valid number", nil |
| "0" | `.invalid` | "Minimum is 1 color", "1" |
| "-5" | `.invalid` | "Minimum is 1 color", "1" |
| "1" | `.valid(1)` | - |
| "50" | `.valid(50)` | - |
| "51" | `.advisory("...", 51)` | Advisory about performance |
| "100" | `.warning("...", 100)` | Warning about UI limits |
| "200" | `.warning("...", 200)` | Maximum practical |
| "201" | `.invalid` | "Maximum is 200 colors", "200" |

### validateHexColor

| Input | Result |
|-------|--------|
| "" | `.invalid("Please enter a hex color", "#8033CC")` |
| "red" | `.invalid("Invalid hex format...", "#8033CC")` |
| "#FFF" | `.invalid("Please use 6-digit hex...", "#FFFFFF")` |
| "8033CC" | `.valid("8033CC")` |
| "#8033CC" | `.valid("8033CC")` |
| "#8033cc" | `.valid("8033CC")` (normalized to uppercase) |

### validateRGBComponent

| Input | Result |
|-------|--------|
| "" | `.invalid("Please enter a value", nil)` |
| "-1" | `.invalid("Value must be 0-255", "0")` |
| "256" | `.invalid("Value must be 0-255", "255")` |
| "0" | `.valid(0)` |
| "128" | `.valid(128)` |
| "255" | `.valid(255)` |

### clampPaletteCount

```swift
clampPaletteCount(0)   // returns 1
clampPaletteCount(100) // returns 100
clampPaletteCount(300) // returns 200
```

## Test Requirements

```swift
// TC-IV-001: Valid palette counts
func testValidPaletteCounts() {
    XCTAssertEqual(InputValidation.validatePaletteCount("8"), .valid(8))
    XCTAssertEqual(InputValidation.validatePaletteCount("1"), .valid(1))
    XCTAssertEqual(InputValidation.validatePaletteCount("50"), .valid(50))
}

// TC-IV-002: Advisory palette counts
func testAdvisoryPaletteCounts() {
    if case .advisory(_, let count) = InputValidation.validatePaletteCount("60") {
        XCTAssertEqual(count, 60)
    } else {
        XCTFail("Expected advisory")
    }
}

// TC-IV-003: Warning palette counts
func testWarningPaletteCounts() {
    if case .warning(_, let count) = InputValidation.validatePaletteCount("150") {
        XCTAssertEqual(count, 150)
    } else {
        XCTFail("Expected warning")
    }
}

// TC-IV-004: Invalid palette counts
func testInvalidPaletteCounts() {
    if case .invalid(_, _) = InputValidation.validatePaletteCount("abc") {
        // pass
    } else {
        XCTFail("Expected invalid")
    }
    
    if case .invalid(_, _) = InputValidation.validatePaletteCount("250") {
        // pass
    } else {
        XCTFail("Expected invalid for >200")
    }
}

// TC-IV-005: Hex color validation
func testHexColorValidation() {
    XCTAssertEqual(InputValidation.validateHexColor("#8033CC"), .valid("8033CC"))
    XCTAssertEqual(InputValidation.validateHexColor("8033CC"), .valid("8033CC"))
    
    if case .invalid(_, _) = InputValidation.validateHexColor("#FFF") {
        // pass - 3-digit not supported
    } else {
        XCTFail("Expected invalid for 3-digit hex")
    }
}

// TC-IV-006: RGB component validation
func testRGBComponentValidation() {
    XCTAssertEqual(InputValidation.validateRGBComponent("0"), .valid(0))
    XCTAssertEqual(InputValidation.validateRGBComponent("128"), .valid(128))
    XCTAssertEqual(InputValidation.validateRGBComponent("255"), .valid(255))
    
    if case .invalid(_, _) = InputValidation.validateRGBComponent("-1") {
        // pass
    } else {
        XCTFail("Expected invalid for negative")
    }
}

// TC-IV-007: Clamp function
func testClampFunction() {
    XCTAssertEqual(InputValidation.clampPaletteCount(-5), 1)
    XCTAssertEqual(InputValidation.clampPaletteCount(0), 1)
    XCTAssertEqual(InputValidation.clampPaletteCount(100), 100)
    XCTAssertEqual(InputValidation.clampPaletteCount(250), 200)
}
```

## Constants

```swift
enum RequestLimits {
    static let warningThreshold = 50
    static let recommendedMaximum = 100
    static let absoluteMaximum = 200
}
```
