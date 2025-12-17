import Foundation
import SwiftUI
import ColorJourney

/// Represents a rendered swatch with all display attributes.
///
/// Contains color value, display properties, and accessibility information.
struct SwatchDisplay: Identifiable, Equatable {
    /// Unique identifier
    let id: UUID
    
    /// Index in the palette
    let index: Int
    
    /// The color value
    let color: ColorJourneyRGB
    
    /// Display size
    let size: SwatchSizePreference
    
    /// Optional label (e.g., index number)
    var label: String?
    
    /// Accessibility contrast note
    var contrastNote: AccessibilityContrastNote?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        index: Int,
        color: ColorJourneyRGB,
        size: SwatchSizePreference = .medium,
        label: String? = nil,
        contrastNote: AccessibilityContrastNote? = nil
    ) {
        self.id = id
        self.index = index
        self.color = color
        self.size = size
        self.label = label
        self.contrastNote = contrastNote
    }
    
    // MARK: - Computed Properties
    
    /// SwiftUI Color representation
    var swiftUIColor: Color {
        color.color
    }
    
    /// Hex string representation
    var hexString: String {
        let r = Int(color.red * 255)
        let g = Int(color.green * 255)
        let b = Int(color.blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// RGB string representation
    var rgbString: String {
        let r = Int(color.red * 255)
        let g = Int(color.green * 255)
        let b = Int(color.blue * 255)
        return "rgb(\(r), \(g), \(b))"
    }
    
    /// Float components string (for code samples)
    var floatString: String {
        String(format: "(%.3f, %.3f, %.3f)", color.red, color.green, color.blue)
    }
    
    /// Relative luminance for contrast calculations
    var relativeLuminance: Double {
        // Using sRGB relative luminance formula
        let r = Double(color.red)
        let g = Double(color.green)
        let b = Double(color.blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Whether text should be light or dark on this color
    var prefersDarkText: Bool {
        relativeLuminance > 0.5
    }
    
    /// Recommended text color for this swatch
    var textColor: Color {
        prefersDarkText ? .black : .white
    }
}

// MARK: - Accessibility Contrast

/// Accessibility contrast information for a swatch
struct AccessibilityContrastNote: Equatable {
    /// Contrast ratio with background
    let contrastRatio: Double
    
    /// WCAG compliance level
    let wcagLevel: WCAGLevel
    
    /// Description for display
    var description: String {
        String(format: "%.1f:1 (%@)", contrastRatio, wcagLevel.rawValue)
    }
}

/// WCAG contrast compliance levels
enum WCAGLevel: String {
    case aaa = "AAA"
    case aa = "AA"
    case aaLarge = "AA Large"
    case fail = "Fail"
    
    /// Initialize from contrast ratio
    init(contrastRatio: Double) {
        if contrastRatio >= 7.0 {
            self = .aaa
        } else if contrastRatio >= 4.5 {
            self = .aa
        } else if contrastRatio >= 3.0 {
            self = .aaLarge
        } else {
            self = .fail
        }
    }
}

// MARK: - Factory Extension

extension SwatchDisplay {
    /// Create swatches from a palette with a given size preference
    static func fromPalette(
        _ colors: [ColorJourneyRGB],
        size: SwatchSizePreference,
        showLabels: Bool = true
    ) -> [SwatchDisplay] {
        colors.enumerated().map { index, color in
            SwatchDisplay(
                index: index,
                color: color,
                size: size,
                label: showLabels ? "\(index)" : nil
            )
        }
    }
}
