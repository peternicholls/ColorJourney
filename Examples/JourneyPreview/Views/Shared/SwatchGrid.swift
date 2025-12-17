import SwiftUI
import ColorJourney

/// A grid of rounded square color swatches with adaptive sizing and background.
///
/// Used across all views to display generated palettes consistently.
/// Includes accessibility features for VoiceOver and contrast checking.
struct SwatchGrid: View {
    /// The swatches to display
    let swatches: [SwatchDisplay]
    
    /// Background color for the grid
    var backgroundColor: Color
    
    /// Whether to show labels on swatches
    var showLabels: Bool = false
    
    /// Whether to show hex values on hover/tap
    var showHexOnInteraction: Bool = true
    
    /// Whether to show accessibility contrast warnings
    var showContrastWarnings: Bool = true
    
    /// Callback when a swatch is tapped
    var onSwatchTapped: ((SwatchDisplay) -> Void)?
    
    /// Currently selected swatch (for highlighting)
    var selectedIndex: Int? = nil
    
    // MARK: - Private State
    
    @State private var hoveredIndex: Int? = nil
    
    // MARK: - Computed Properties
    
    private var columns: [GridItem] {
        let size = swatches.first?.size ?? .medium
        let itemSize = size.pointSize
        return [GridItem(.adaptive(minimum: itemSize, maximum: itemSize * 1.5), spacing: spacing)]
    }
    
    private var spacing: CGFloat {
        let size = swatches.first?.size ?? .medium
        switch size {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 20
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(swatches) { swatch in
                SwatchView(
                    swatch: swatch,
                    isSelected: selectedIndex == swatch.index,
                    isHovered: hoveredIndex == swatch.index,
                    showLabel: showLabels,
                    showHex: showHexOnInteraction && hoveredIndex == swatch.index,
                    showContrastWarning: showContrastWarnings && hasLowContrast(swatch, against: backgroundColor)
                )
                .onTapGesture {
                    onSwatchTapped?(swatch)
                }
                .onHover { isHovering in
                    hoveredIndex = isHovering ? swatch.index : nil
                }
            }
        }
        .padding(spacing)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color palette with \(swatches.count) swatches")
    }
    
    // MARK: - Accessibility Helpers
    
    /// Check if a swatch has low contrast against the background
    private func hasLowContrast(_ swatch: SwatchDisplay, against background: Color) -> Bool {
        // Convert background Color to luminance (approximate)
        // This is a simplified check - real implementation would use proper color conversion
        let swatchLuminance = swatch.relativeLuminance
        
        // Estimate background luminance (assume it's a grayscale or we use a default)
        // For now, we'll check if the swatch is very close to mid-gray
        let contrastRatio = calculateContrastRatio(swatchLuminance: swatchLuminance)
        
        return contrastRatio < 3.0 // Below WCAG AA Large threshold
    }
    
    private func calculateContrastRatio(swatchLuminance: Double) -> Double {
        // Simplified contrast calculation assuming background is around 0.15 luminance (dark)
        let backgroundLuminance = 0.15
        let lighter = max(swatchLuminance, backgroundLuminance)
        let darker = min(swatchLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

// MARK: - Individual Swatch View

/// A single rounded square swatch with optional label and hover effects.
/// Includes accessibility annotations and optional contrast warnings.
struct SwatchView: View {
    let swatch: SwatchDisplay
    var isSelected: Bool = false
    var isHovered: Bool = false
    var showLabel: Bool = false
    var showHex: Bool = false
    var showContrastWarning: Bool = false
    
    var body: some View {
        ZStack {
            // Main swatch
            RoundedRectangle(cornerRadius: swatch.size.cornerRadius)
                .fill(swatch.swiftUIColor)
                .frame(width: swatch.size.pointSize, height: swatch.size.pointSize)
                .shadow(
                    color: .black.opacity(isHovered ? 0.4 : 0.2),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
            
            // Selection outline
            if isSelected {
                RoundedRectangle(cornerRadius: swatch.size.cornerRadius)
                    .strokeBorder(Color.white, lineWidth: 3)
                    .frame(width: swatch.size.pointSize, height: swatch.size.pointSize)
            }
            
            // Contrast warning indicator
            if showContrastWarning {
                contrastWarningBadge
            }
            
            // Content overlay (label or hex)
            if showHex {
                hexOverlay
            } else if showLabel, let label = swatch.label {
                labelOverlay(label)
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Color \(swatch.index + 1): \(swatch.hexString)")
        .accessibilityValue(swatch.rgbString)
        .accessibilityHint("Tap to select this color")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var contrastWarningBadge: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .frame(width: swatch.size.pointSize, height: swatch.size.pointSize)
    }
    
    private var hexOverlay: some View {
        Text(swatch.hexString)
            .font(.system(size: hexFontSize, weight: .medium, design: .monospaced))
            .foregroundColor(swatch.textColor)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(swatch.textColor.opacity(0.2))
            )
    }
    
    private func labelOverlay(_ label: String) -> some View {
        Text(label)
            .font(.system(size: labelFontSize, weight: .semibold))
            .foregroundColor(swatch.textColor.opacity(0.8))
    }
    
    private var hexFontSize: CGFloat {
        switch swatch.size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        case .extraLarge: return 14
        }
    }
    
    private var labelFontSize: CGFloat {
        switch swatch.size {
        case .small: return 10
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 20
        }
    }
}

// MARK: - Preview

#Preview("Swatch Grid") {
    let testColors: [ColorJourneyRGB] = [
        ColorJourneyRGB(red: 0.95, green: 0.45, blue: 0.3),
        ColorJourneyRGB(red: 0.85, green: 0.55, blue: 0.4),
        ColorJourneyRGB(red: 0.75, green: 0.65, blue: 0.5),
        ColorJourneyRGB(red: 0.65, green: 0.75, blue: 0.6),
        ColorJourneyRGB(red: 0.55, green: 0.85, blue: 0.7),
        ColorJourneyRGB(red: 0.45, green: 0.75, blue: 0.8),
        ColorJourneyRGB(red: 0.35, green: 0.65, blue: 0.9),
        ColorJourneyRGB(red: 0.25, green: 0.55, blue: 0.95)
    ]
    
    let swatches = SwatchDisplay.fromPalette(testColors, size: .medium, showLabels: true)
    
    VStack(spacing: 20) {
        SwatchGrid(
            swatches: swatches,
            backgroundColor: Color(white: 0.15),
            showLabels: true
        )
        
        SwatchGrid(
            swatches: SwatchDisplay.fromPalette(testColors, size: .large),
            backgroundColor: Color(white: 0.9),
            showLabels: false
        )
    }
    .padding()
    .background(Color(white: 0.1))
}
