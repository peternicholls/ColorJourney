import Foundation
import ColorJourney

// MARK: - ANSI Color Support

/// ANSI color escape codes for terminal output with 24-bit RGB.
struct ANSIColor {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    
    /// ANSI escape code for this color
    var escapeCode: String {
        "38;2;\(r);\(g);\(b)"
    }
    
    /// Create a colored swatch using Unicode block characters
    /// - Parameter width: Number of block characters (default: 4)
    /// - Returns: Colored string representation
    func swatch(width: Int = 4) -> String {
        "\u{001B}[\(escapeCode)m" + String(repeating: "█", count: width) + "\u{001B}[0m"
    }
    
    /// Initialize from ColorJourneyRGB
    init(from color: ColorJourneyRGB) {
        self.r = UInt8(color.red * 255)
        self.g = UInt8(color.green * 255)
        self.b = UInt8(color.blue * 255)
    }
    
    /// Initialize from RGB components
    init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}

// MARK: - Formatting Helpers

/// Create a separator line
/// - Parameter length: Length of the line (default: 80)
func separator(_ length: Int = 80) -> String {
    String(repeating: "=", count: length)
}

/// Create a dash line (shorter separator)
/// - Parameter length: Length of the line (default: 40)
func dash(_ length: Int = 40) -> String {
    String(repeating: "-", count: length)
}

/// Display a row of colors with swatches
/// - Parameter colors: Array of colors to display
func displayColorRow(_ colors: [ColorJourneyRGB]) {
    var row = "   "
    for color in colors {
        let ansi = ANSIColor(from: color)
        row += ansi.swatch() + " "
    }
    print(row)
}

/// Display colors in a grid format
/// - Parameters:
///   - colors: Array of colors to display
///   - columns: Number of columns in the grid
func displayColorGrid(_ colors: [ColorJourneyRGB], columns: Int = 8) {
    for chunk in colors.chunked(into: columns) {
        displayColorRow(chunk)
    }
}

/// Format RGB values for display
/// - Parameter color: Color to format
/// - Returns: Formatted string like "RGB(0.50, 0.30, 0.80)"
func formatRGB(_ color: ColorJourneyRGB) -> String {
    "RGB(\(String(format: "%.2f", color.red)), \(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
}

/// Display a color with swatch and RGB values
/// - Parameters:
///   - color: Color to display
///   - label: Optional label text
func displayColor(_ color: ColorJourneyRGB, label: String? = nil) {
    let ansi = ANSIColor(from: color)
    let rgb = formatRGB(color)
    if let label = label {
        print("\(ansi.swatch())  \(label): \(rgb)")
    } else {
        print("\(ansi.swatch())  \(rgb)")
    }
}

// MARK: - Comparison Helpers

/// Check if two colors are equal (with tolerance for floating-point precision)
/// - Parameters:
///   - a: First color
///   - b: Second color
///   - tolerance: Maximum difference per component (default: 1e-5)
/// - Returns: True if colors are approximately equal
func colorsEqual(_ a: ColorJourneyRGB, _ b: ColorJourneyRGB, tolerance: Float = 1e-5) -> Bool {
    abs(a.red - b.red) <= tolerance &&
    abs(a.green - b.green) <= tolerance &&
    abs(a.blue - b.blue) <= tolerance
}

/// Check if two color arrays are equal
/// - Parameters:
///   - a: First array
///   - b: Second array
/// - Returns: True if arrays have same length and all colors match
func colorsEqual(_ a: [ColorJourneyRGB], _ b: [ColorJourneyRGB]) -> Bool {
    guard a.count == b.count else { return false }
    for (c1, c2) in zip(a, b) {
        if !colorsEqual(c1, c2) {
            return false
        }
    }
    return true
}

// MARK: - Array Extensions

extension Array {
    /// Split array into chunks of specified size
    /// - Parameter size: Maximum size of each chunk
    /// - Returns: Array of arrays (chunks)
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
