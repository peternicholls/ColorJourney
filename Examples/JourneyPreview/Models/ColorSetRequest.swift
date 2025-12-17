import Foundation
import ColorJourney

/// Represents a request for a color palette with all configurable parameters.
///
/// Used by view models to capture user input and generate palettes consistently.
struct ColorSetRequest {
    // MARK: - Core Parameters
    
    /// Number of colors to generate (1-200)
    var count: Int
    
    /// Delta target for perceptual spacing (ΔE range)
    var deltaTarget: DeltaTarget
    
    /// Background color for swatch display
    var backgroundColor: ColorJourneyRGB
    
    /// Swatch display size preference
    var swatchSize: SwatchSizePreference
    
    // MARK: - Style Parameters
    
    /// Journey style preset name (string representation)
    var styleName: String
    
    /// Anchor color for palette generation
    var anchorColor: ColorJourneyRGB
    
    // MARK: - Safety Flags
    
    /// Whether to bypass large palette warnings (user acknowledged)
    var bypassLargeWarning: Bool
    
    // MARK: - Initialization
    
    init(
        count: Int = 8,
        deltaTarget: DeltaTarget = .medium,
        backgroundColor: ColorJourneyRGB = ColorJourneyRGB(red: 0.1, green: 0.1, blue: 0.1),
        swatchSize: SwatchSizePreference = .medium,
        style: JourneyStyle = .balanced,
        anchorColor: ColorJourneyRGB = ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
        bypassLargeWarning: Bool = false
    ) {
        self.count = count
        self.deltaTarget = deltaTarget
        self.backgroundColor = backgroundColor
        self.swatchSize = swatchSize
        self.styleName = Self.styleToString(style)
        self.anchorColor = anchorColor
        self.bypassLargeWarning = bypassLargeWarning
    }
    
    // MARK: - Computed Properties
    
    /// Get the JourneyStyle from the stored name
    var style: JourneyStyle {
        Self.stringToStyle(styleName)
    }
    
    // MARK: - Validation
    
    /// Validates the request and returns any issues
    var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []
        
        if count < 1 {
            errors.append(.countTooLow)
        }
        if count > RequestLimits.absoluteMaximum {
            errors.append(.countExceedsMaximum)
        }
        
        return errors
    }
    
    /// Whether the request is valid for generation
    var isValid: Bool {
        validationErrors.isEmpty
    }
    
    /// Whether this request exceeds the warning threshold
    var exceedsWarningThreshold: Bool {
        count > RequestLimits.warningThreshold
    }
    
    /// Whether this request exceeds the absolute maximum
    var exceedsMaximum: Bool {
        count > RequestLimits.absoluteMaximum
    }
    
    // MARK: - Style Conversion Helpers
    
    static func styleToString(_ style: JourneyStyle) -> String {
        switch style {
        case .balanced: return "balanced"
        case .pastelDrift: return "pastelDrift"
        case .vividLoop: return "vividLoop"
        case .nightMode: return "nightMode"
        case .warmEarth: return "warmEarth"
        case .coolSky: return "coolSky"
        case .custom: return "custom"
        }
    }
    
    static func stringToStyle(_ name: String) -> JourneyStyle {
        switch name {
        case "balanced": return .balanced
        case "pastelDrift": return .pastelDrift
        case "vividLoop": return .vividLoop
        case "nightMode": return .nightMode
        case "warmEarth": return .warmEarth
        case "coolSky": return .coolSky
        case "custom": return .custom
        default: return .balanced
        }
    }
}

// MARK: - Supporting Types

/// Delta target for perceptual color spacing
enum DeltaTarget: String, CaseIterable, Identifiable {
    case tight = "Tight"
    case medium = "Medium"
    case wide = "Wide"
    
    var id: String { rawValue }
    
    /// Description for UI display
    var description: String {
        switch self {
        case .tight: return "Subtle spacing (ΔE ~0.02)"
        case .medium: return "Balanced spacing (ΔE ~0.035)"
        case .wide: return "Strong spacing (ΔE ~0.05)"
        }
    }
    
    /// Maps to contrast level for C core
    var contrastLevel: ContrastLevel {
        switch self {
        case .tight: return .low
        case .medium: return .medium
        case .wide: return .high
        }
    }
}

/// Swatch size preference for display
enum SwatchSizePreference: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var id: String { rawValue }
    
    /// Size in points for swatch display
    var pointSize: CGFloat {
        switch self {
        case .small: return 44
        case .medium: return 80
        case .large: return 110
        case .extraLarge: return 150
        }
    }
    
    /// Corner radius for rounded squares
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 20
        }
    }
}

/// Request limits and thresholds
enum RequestLimits {
    /// Warning threshold (show advisory)
    static let warningThreshold: Int = 50
    
    /// Absolute maximum (refuse beyond)
    static let absoluteMaximum: Int = 200
    
    /// Recommended maximum for smooth UI
    static let recommendedMaximum: Int = 100
}

/// Validation errors for requests
enum ValidationError: LocalizedError, Equatable {
    case countTooLow
    case countExceedsMaximum
    case invalidDelta
    
    var errorDescription: String? {
        switch self {
        case .countTooLow:
            return "Palette count must be at least 1"
        case .countExceedsMaximum:
            return "Palette count cannot exceed \(RequestLimits.absoluteMaximum)"
        case .invalidDelta:
            return "Delta target is invalid"
        }
    }
}
