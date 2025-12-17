import Foundation
import ColorJourney

/// Input validation utilities for palette generation requests.
///
/// Provides validation, clamping, and error messaging for user inputs.
enum InputValidation {
    // MARK: - Palette Count
    
    /// Validate palette count input
    static func validatePaletteCount(_ count: Int) -> ValidationResult {
        if count < 1 {
            return .invalid(
                error: "Palette size must be at least 1",
                suggestion: "Enter a number between 1 and \(RequestLimits.absoluteMaximum)"
            )
        }
        
        if count > RequestLimits.absoluteMaximum {
            return .invalid(
                error: "Palette size cannot exceed \(RequestLimits.absoluteMaximum)",
                suggestion: "Consider using batched generation for larger sets"
            )
        }
        
        if count > RequestLimits.recommendedMaximum {
            return .warning(
                message: "Large palettes (>\(RequestLimits.recommendedMaximum)) may affect UI performance",
                clampedValue: count
            )
        }
        
        if count > RequestLimits.warningThreshold {
            return .advisory(
                message: "Palette will use grouped display for better performance",
                value: count
            )
        }
        
        return .valid(count)
    }
    
    /// Clamp palette count to valid range
    static func clampPaletteCount(_ count: Int) -> Int {
        max(1, min(count, RequestLimits.absoluteMaximum))
    }
    
    // MARK: - Numeric Input
    
    /// Parse and validate numeric string input
    static func parseNumericInput(_ input: String, range: ClosedRange<Int>) -> ValidationResult {
        guard let value = Int(input.trimmingCharacters(in: .whitespaces)) else {
            return .invalid(
                error: "Please enter a valid number",
                suggestion: "Enter a number between \(range.lowerBound) and \(range.upperBound)"
            )
        }
        
        if value < range.lowerBound {
            return .invalid(
                error: "Value must be at least \(range.lowerBound)",
                suggestion: nil
            )
        }
        
        if value > range.upperBound {
            return .invalid(
                error: "Value cannot exceed \(range.upperBound)",
                suggestion: nil
            )
        }
        
        return .valid(value)
    }
    
    // MARK: - Color Input
    
    /// Validate hex color input
    static func validateHexColor(_ hex: String) -> ColorValidationResult {
        let cleanHex = hex.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
        
        guard cleanHex.count == 6 else {
            return .invalid("Hex color must be 6 characters (e.g., FF5500)")
        }
        
        guard cleanHex.allSatisfy({ $0.isHexDigit }) else {
            return .invalid("Invalid hex characters. Use 0-9 and A-F only.")
        }
        
        // Parse to RGB
        guard let rgb = parseHexToRGB(cleanHex) else {
            return .invalid("Could not parse hex color")
        }
        
        return .valid(rgb)
    }
    
    /// Parse hex string to ColorJourneyRGB
    static func parseHexToRGB(_ hex: String) -> ColorJourneyRGB? {
        let cleanHex = hex.replacingOccurrences(of: "#", with: "")
        
        guard cleanHex.count == 6 else { return nil }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        let r = Float((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Float((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Float(rgbValue & 0x0000FF) / 255.0
        
        return ColorJourneyRGB(red: r, green: g, blue: b)
    }
    
    // MARK: - RGB Component
    
    /// Validate RGB component (0-255)
    static func validateRGBComponent(_ value: Int) -> ValidationResult {
        if value < 0 {
            return .invalid(error: "RGB value cannot be negative", suggestion: "Use 0-255")
        }
        if value > 255 {
            return .invalid(error: "RGB value cannot exceed 255", suggestion: "Use 0-255")
        }
        return .valid(value)
    }
    
    /// Validate float RGB component (0.0-1.0)
    static func validateFloatRGBComponent(_ value: Float) -> Bool {
        value >= 0.0 && value <= 1.0
    }
}

// MARK: - Validation Results

/// Result of validating an integer input
enum ValidationResult {
    case valid(Int)
    case advisory(message: String, value: Int)
    case warning(message: String, clampedValue: Int)
    case invalid(error: String, suggestion: String?)
    
    var isValid: Bool {
        switch self {
        case .valid, .advisory, .warning:
            return true
        case .invalid:
            return false
        }
    }
    
    var value: Int? {
        switch self {
        case .valid(let v), .advisory(_, let v), .warning(_, let v):
            return v
        case .invalid:
            return nil
        }
    }
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case .advisory(let msg, _), .warning(let msg, _):
            return msg
        case .invalid(let err, _):
            return err
        }
    }
}

/// Result of validating a color input
enum ColorValidationResult {
    case valid(ColorJourneyRGB)
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var color: ColorJourneyRGB? {
        if case .valid(let rgb) = self { return rgb }
        return nil
    }
    
    var error: String? {
        if case .invalid(let msg) = self { return msg }
        return nil
    }
}
