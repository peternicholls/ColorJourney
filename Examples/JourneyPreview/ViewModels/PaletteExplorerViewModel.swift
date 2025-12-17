import SwiftUI
import Combine
import ColorJourney

/// View model for the Palette Explorer view.
///
/// Manages palette generation, user input state, and UI updates.
@MainActor
final class PaletteExplorerViewModel: ObservableObject {
    // MARK: - Published State
    
    /// Number of colors to generate
    @Published var paletteCount: Int = 12
    
    /// Delta spacing target
    @Published var deltaTarget: DeltaTarget = .medium
    
    /// Selected style name
    @Published var selectedStyleName: String = "balanced"
    
    /// Swatch size slider value (0-3 maps to small-extraLarge)
    @Published var swatchSizeValue: Double = 1
    
    /// Anchor color (SwiftUI binding)
    @Published var anchorSwiftUIColor: Color = Color(red: 0.5, green: 0.2, blue: 0.8)
    
    /// Background color (SwiftUI binding)
    @Published var backgroundSwiftUIColor: Color = Color(white: 0.15)
    
    /// Generated swatches
    @Published private(set) var swatches: [SwatchDisplay] = []
    
    /// Code snippets
    @Published private(set) var codeSnippets: [CodeSnippet] = []
    
    /// Current advisory message
    @Published private(set) var currentAdvisory: AdvisoryInfo? = nil
    
    /// Generation timing string
    @Published private(set) var generationTiming: String? = nil
    
    /// Selected swatch index
    @Published var selectedSwatchIndex: Int? = nil
    
    // MARK: - Computed Properties
    
    /// Available style names
    let availableStyles = ["balanced", "pastelDrift", "vividLoop", "nightMode", "warmEarth", "coolSky"]
    
    /// Background color presets
    let backgroundPresets: [Color] = [
        Color(white: 0.1),
        Color(white: 0.3),
        Color(white: 0.5),
        Color(white: 0.8),
        Color(white: 0.95)
    ]
    
    /// Current swatch size preference
    var swatchSize: SwatchSizePreference {
        switch Int(swatchSizeValue.rounded()) {
        case 0: return .small
        case 1: return .medium
        case 2: return .large
        default: return .extraLarge
        }
    }
    
    /// Current anchor color as ColorJourneyRGB
    var anchorColor: ColorJourneyRGB {
        colorToRGB(anchorSwiftUIColor)
    }
    
    /// Current background color as ColorJourneyRGB
    var backgroundColor: ColorJourneyRGB {
        colorToRGB(backgroundSwiftUIColor)
    }
    
    /// Current journey style
    var journeyStyle: JourneyStyle {
        switch selectedStyleName {
        case "balanced": return .balanced
        case "pastelDrift": return .pastelDrift
        case "vividLoop": return .vividLoop
        case "nightMode": return .nightMode
        case "warmEarth": return .warmEarth
        case "coolSky": return .coolSky
        default: return .balanced
        }
    }
    
    // MARK: - Private
    
    private var journey: ColorJourney?
    
    // MARK: - Actions
    
    /// Generate palette based on current settings
    func generatePalette() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Update advisory based on count
        updateAdvisory()
        
        // Create config
        let config = ColorJourneyConfig.singleAnchor(anchorColor, style: journeyStyle)
        journey = ColorJourney(config: config)
        
        // Generate colors
        guard let journey = journey else { return }
        let colors = journey.discrete(count: paletteCount)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let durationMs = (endTime - startTime) * 1000
        
        // Update timing
        generationTiming = String(format: "%.2fms (%d colors)", durationMs, paletteCount)
        
        // Create swatches
        swatches = SwatchDisplay.fromPalette(colors, size: swatchSize, showLabels: true)
        
        // Generate code snippets
        generateCodeSnippets(colors: colors)
    }
    
    /// Record a copy action
    func recordCopy(snippet: CodeSnippet) {
        // Could track analytics here
    }
    
    // MARK: - Private Methods
    
    private func updateAdvisory() {
        if paletteCount > RequestLimits.absoluteMaximum {
            currentAdvisory = AdvisoryInfo(
                type: .error,
                title: "Palette Too Large",
                message: "Maximum supported palette size is \(RequestLimits.absoluteMaximum) colors.",
                technicalDetails: nil
            )
        } else if paletteCount > RequestLimits.recommendedMaximum {
            currentAdvisory = AdvisoryInfo(
                type: .warning,
                title: "Large Palette",
                message: "Palettes above \(RequestLimits.recommendedMaximum) colors may affect performance. Consider using the Large Palettes view for better handling.",
                technicalDetails: "Generation: ~\(String(format: "%.1f", Double(paletteCount) * 0.0006))ms\nMemory: ~\(paletteCount * 12) bytes"
            )
        } else if paletteCount > RequestLimits.warningThreshold {
            currentAdvisory = AdvisoryInfo(
                type: .info,
                title: "Performance Note",
                message: "ColorJourney can generate this palette in microseconds. No performance concerns at this size.",
                technicalDetails: nil
            )
        } else {
            currentAdvisory = nil
        }
    }
    
    private func generateCodeSnippets(colors: [ColorJourneyRGB]) {
        let request = ColorSetRequest(
            count: paletteCount,
            deltaTarget: deltaTarget,
            style: journeyStyle,
            anchorColor: anchorColor
        )
        
        codeSnippets = [
            CodeSnippet(
                type: .swiftUsage,
                code: CodeGenerator.generateSwiftUsage(request: request)
            ),
            CodeSnippet(
                type: .swiftColors,
                code: CodeGenerator.generateSwiftColors(colors: colors)
            ),
            CodeSnippet(
                type: .css,
                code: CodeGenerator.generateCSS(colors: colors)
            ),
            CodeSnippet(
                type: .cssVariables,
                code: CodeGenerator.generateCSSVariables(colors: colors)
            )
        ]
    }
    
    private func colorToRGB(_ color: Color) -> ColorJourneyRGB {
        // SwiftUI Color to RGB components
        #if canImport(AppKit)
        let nsColor = NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorJourneyRGB(red: Float(r), green: Float(g), blue: Float(b))
        #else
        // Fallback - try to extract from description or use default
        return ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        #endif
    }
}

// MARK: - Advisory Info

/// Information for displaying an advisory box
struct AdvisoryInfo {
    let type: AdvisoryType
    let title: String
    let message: String
    let technicalDetails: String?
}
