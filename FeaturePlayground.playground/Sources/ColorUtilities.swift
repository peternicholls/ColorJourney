import Foundation
import ColorJourney
import SwiftUI
import PlaygroundSupport

// MARK: - ANSI Color Support

/// ANSI color escape codes for terminal output with 24-bit RGB.
public struct ANSIColor {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8
    
    /// ANSI escape code for this color
    public var escapeCode: String {
        "38;2;\(r);\(g);\(b)"
    }
    
    /// Create a colored swatch using Unicode block characters
    /// - Parameter width: Number of block characters (default: 4)
    /// - Returns: Colored string representation
    public func swatch(width: Int = 4) -> String {
        "\u{001B}[\(escapeCode)m" + String(repeating: "█", count: width) + "\u{001B}[0m"
    }
    
    /// Initialize from ColorJourneyRGB
    public init(from color: ColorJourneyRGB) {
        self.r = UInt8(color.red * 255)
        self.g = UInt8(color.green * 255)
        self.b = UInt8(color.blue * 255)
    }
    
    /// Initialize from RGB components
    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}

// MARK: - Formatting Helpers

/// Create a separator line
/// - Parameter length: Length of the line (default: 80)
public func separator(_ length: Int = 80) -> String {
    String(repeating: "=", count: length)
}

/// Create a dash line (shorter separator)
/// - Parameter length: Length of the line (default: 40)
public func dash(_ length: Int = 40) -> String {
    String(repeating: "-", count: length)
}

/// Display a row of colors with swatches
/// - Parameter colors: Array of colors to display
public func displayColorRow(_ colors: [ColorJourneyRGB]) {
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
public func displayColorGrid(_ colors: [ColorJourneyRGB], columns: Int = 8) {
    for chunk in colors.chunked(into: columns) {
        displayColorRow(chunk)
    }
}

/// Format RGB values for display
/// - Parameter color: Color to format
/// - Returns: Formatted string like "RGB(0.50, 0.30, 0.80)"
public func formatRGB(_ color: ColorJourneyRGB) -> String {
    "RGB(\(String(format: "%.2f", color.red)), \(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))"
}

/// Display a color with swatch and RGB values
/// - Parameters:
///   - color: Color to display
///   - label: Optional label text
public func displayColor(_ color: ColorJourneyRGB, label: String? = nil) {
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
public func colorsEqual(_ a: ColorJourneyRGB, _ b: ColorJourneyRGB, tolerance: Float = 1e-5) -> Bool {
    abs(a.red - b.red) <= tolerance &&
    abs(a.green - b.green) <= tolerance &&
    abs(a.blue - b.blue) <= tolerance
}

/// Check if two color arrays are equal
/// - Parameters:
///   - a: First array
///   - b: Second array
/// - Returns: True if arrays have same length and all colors match
public func colorsEqual(_ a: [ColorJourneyRGB], _ b: [ColorJourneyRGB]) -> Bool {
    guard a.count == b.count else { return false }
    for (c1, c2) in zip(a, b) {
        if !colorsEqual(c1, c2) {
            return false
        }
    }
    return true
}

// MARK: - Array Extensions

public extension Array {
    /// Split array into chunks of specified size
    /// - Parameter size: Maximum size of each chunk
    /// - Returns: Array of arrays (chunks)
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - SwiftUI Playground Visualisation



/// A simple SwiftUI grid view to visualise ColorJourneyRGB values.
public struct ColorGridView: View {
    private let colors: [ColorJourneyRGB]
    private let columns: Int
    
    public init(colors: [ColorJourneyRGB], columns: Int = 8) {
        self.colors = colors
        self.columns = max(columns, 1)
    }
    
    public var body: some View {
        let rows = colors.chunked(into: columns)
        
        return VStack(spacing: 4) {
            ForEach(Array(rows.indices), id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(Array(rows[rowIndex].indices), id: \.self) { columnIndex in
                        let color = rows[rowIndex][columnIndex]
                        Rectangle()
                            .fill(Color(
                                red: Double(color.red),
                                green: Double(color.green),
                                blue: Double(color.blue)
                            ))
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
    }
}

/// Convenience helper to show a grid of colors in the playground live view.
/// - Parameters:
///   - colors: Colors to display
///   - columns: Number of columns in the grid
public func showColorGridLive(_ colors: [ColorJourneyRGB], columns: Int = 8) {
    let view = ColorGridView(colors: colors, columns: columns)
    PlaygroundPage.current.setLiveView(view)
}

/// A simple view to show a single color swatch with an optional label.
public struct SingleColorView: View {
    private let color: ColorJourneyRGB
    private let label: String?
    
    public init(color: ColorJourneyRGB, label: String? = nil) {
        self.color = color
        self.label = label
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color(
                    red: Double(color.red),
                    green: Double(color.green),
                    blue: Double(color.blue)
                ))
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            if let label = label {
                Text(label)
                    .font(.headline)
            }
            
            Text(formatRGB(color))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// Convenience helper to show a single color in the playground live view.
public func showColorLive(_ color: ColorJourneyRGB, label: String? = nil) {
    let view = SingleColorView(color: color, label: label)
    PlaygroundPage.current.setLiveView(view)
}



