import Foundation
import ColorJourney

/// Represents a generated code snippet for displaying to users.
///
/// Contains code in various formats (Swift, CSS) tied to current palette parameters.
struct CodeSnippet: Identifiable, Equatable {
    /// Unique identifier
    let id: UUID
    
    /// Type of code snippet
    let type: SnippetType
    
    /// The actual code content
    let code: String
    
    /// Display title
    var title: String {
        type.displayTitle
    }
    
    /// Copy state for UI feedback
    var copyState: CopyState
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        type: SnippetType,
        code: String,
        copyState: CopyState = .idle
    ) {
        self.id = id
        self.type = type
        self.code = code
        self.copyState = copyState
    }
}

// MARK: - Snippet Types

/// Types of code snippets supported
enum SnippetType: String, CaseIterable, Identifiable {
    case swiftUsage = "swift_usage"
    case swiftColors = "swift_colors"
    case css = "css"
    case cssVariables = "css_variables"
    
    var id: String { rawValue }
    
    /// Display title for UI
    var displayTitle: String {
        switch self {
        case .swiftUsage: return "Swift Usage"
        case .swiftColors: return "Swift Colors"
        case .css: return "CSS"
        case .cssVariables: return "CSS Variables"
        }
    }
    
    /// Language identifier for syntax highlighting
    var language: String {
        switch self {
        case .swiftUsage, .swiftColors: return "swift"
        case .css, .cssVariables: return "css"
        }
    }
    
    /// File extension
    var fileExtension: String {
        switch self {
        case .swiftUsage, .swiftColors: return "swift"
        case .css, .cssVariables: return "css"
        }
    }
}

/// Copy button state for UI feedback
enum CopyState: Equatable {
    case idle
    case copying
    case success
    case failed(String)
    
    /// Whether copy is in progress
    var isCopying: Bool {
        if case .copying = self { return true }
        return false
    }
    
    /// Whether copy succeeded
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Code Generation

/// Generator for code snippets from palette parameters
enum CodeGenerator {
    /// Generate Swift usage code
    static func generateSwiftUsage(request: ColorSetRequest) -> String {
        let styleName = request.styleName
        let anchorCode = colorToSwiftCode(request.anchorColor)
        
        return """
        import ColorJourney
        
        // Create a journey from your anchor color
        let journey = ColorJourney(
            config: .singleAnchor(
                \(anchorCode),
                style: .\(styleName)
            )
        )
        
        // Generate \(request.count) discrete colors
        let palette = journey.discrete(count: \(request.count))
        
        // Use in SwiftUI
        ForEach(palette.indices, id: \\.self) { i in
            Rectangle().fill(palette[i].color)
        }
        """
    }
    
    /// Generate Swift color array code
    static func generateSwiftColors(colors: [ColorJourneyRGB]) -> String {
        guard !colors.isEmpty else { return "// No colors generated" }
        
        var lines = ["let colors: [ColorJourneyRGB] = ["]
        for (index, color) in colors.enumerated() {
            let comma = index < colors.count - 1 ? "," : ""
            lines.append("    ColorJourneyRGB(red: \(String(format: "%.3f", color.red)), green: \(String(format: "%.3f", color.green)), blue: \(String(format: "%.3f", color.blue)))\(comma)")
        }
        lines.append("]")
        return lines.joined(separator: "\n")
    }
    
    /// Generate CSS color definitions
    static func generateCSS(colors: [ColorJourneyRGB]) -> String {
        guard !colors.isEmpty else { return "/* No colors generated */" }
        
        var lines = ["/* Generated Palette - \(colors.count) colors */"]
        for (index, color) in colors.enumerated() {
            let hex = colorToHex(color)
            lines.append(".color-\(index) { background-color: \(hex); }")
        }
        return lines.joined(separator: "\n")
    }
    
    /// Generate CSS custom properties
    static func generateCSSVariables(colors: [ColorJourneyRGB]) -> String {
        guard !colors.isEmpty else { return "/* No colors generated */" }
        
        var lines = [":root {", "  /* Generated Palette - \(colors.count) colors */"]
        for (index, color) in colors.enumerated() {
            let hex = colorToHex(color)
            lines.append("  --palette-color-\(index): \(hex);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Helpers
    
    private static func colorToSwiftCode(_ color: ColorJourneyRGB) -> String {
        return "ColorJourneyRGB(red: \(String(format: "%.3f", color.red)), green: \(String(format: "%.3f", color.green)), blue: \(String(format: "%.3f", color.blue)))"
    }
    
    private static func colorToHex(_ color: ColorJourneyRGB) -> String {
        let r = Int(color.red * 255)
        let g = Int(color.green * 255)
        let b = Int(color.blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
