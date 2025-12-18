import SwiftUI
import Combine
import ColorJourney

/// View model for the Usage Examples view.
///
/// Manages code generation and example display.
@MainActor
final class UsageExamplesViewModel: ObservableObject {
    // MARK: - Published State
    
    /// Number of colors for examples
    @Published var colorCount: Int = 8
    
    /// Selected style
    @Published var selectedStyle: String = "balanced"
    
    /// Preview swatches
    @Published private(set) var previewSwatches: [SwatchDisplay] = []
    
    /// Copy count for analytics
    @Published private(set) var copyCount: Int = 0
    
    // MARK: - Computed Properties
    
    /// Current journey style
    var journeyStyle: JourneyStyle {
        switch selectedStyle {
        case "balanced": return .balanced
        case "pastelDrift": return .pastelDrift
        case "vividLoop": return .vividLoop
        case "nightMode": return .nightMode
        case "warmEarth": return .warmEarth
        case "coolSky": return .coolSky
        default: return .balanced
        }
    }
    
    /// Swift usage code snippet
    var swiftUsageSnippet: CodeSnippet {
        let request = ColorSetRequest(
            count: colorCount,
            style: journeyStyle,
            anchorColor: defaultAnchor
        )
        return CodeSnippet(
            type: .swiftUsage,
            code: CodeGenerator.generateSwiftUsage(request: request)
        )
    }
    
    /// Swift colors array snippet
    var swiftColorsSnippet: CodeSnippet {
        CodeSnippet(
            type: .swiftColors,
            code: CodeGenerator.generateSwiftColors(colors: generatedColors)
        )
    }
    
    /// CSS snippet
    var cssSnippet: CodeSnippet {
        CodeSnippet(
            type: .css,
            code: CodeGenerator.generateCSS(colors: generatedColors)
        )
    }
    
    /// CSS variables snippet
    var cssVariablesSnippet: CodeSnippet {
        CodeSnippet(
            type: .cssVariables,
            code: CodeGenerator.generateCSSVariables(colors: generatedColors)
        )
    }
    
    // MARK: - Private
    
    private var generatedColors: [ColorJourneyRGB] = []
    private let defaultAnchor = ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)
    
    // MARK: - Actions
    
    /// Generate examples based on current settings
    func generateExamples() {
        let config = ColorJourneyConfig.singleAnchor(defaultAnchor, style: journeyStyle)
        let journey = ColorJourney(config: config)
        
        generatedColors = journey.discrete(count: colorCount)
        previewSwatches = SwatchDisplay.fromPalette(generatedColors, size: .medium, showLabels: false)
    }
    
    /// Record a copy action
    func recordCopy() {
        copyCount += 1
    }
}
