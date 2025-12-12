/*:
 [Previous: Color Basics](@previous) | [Next: Access Patterns](@next)

 # Journey Styles

 Explore all 6 pre-configured journey styles.

 Each style is a preset combination of perceptual biases (lightness, chroma, contrast, temperature)
 optimized for common use cases. Use these as-is or as starting points for customization.
 */

import SwiftUI
import PlaygroundSupport
import ColorJourney

#if os(macOS)
import AppKit
#endif

// MARK: - Supporting Views

struct JourneyStyleCardView: View {
    let title: String
    let description: String
    let colors: [ColorJourneyRGB]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(0..<colors.count, id: \.self) { index in
                    let color = colors[index]

                    // Convert from linear [0, 1] to sRGB-ish for display
                    let sr = pow(Double(color.red), 1.0 / 2.2)
                    let sg = pow(Double(color.green), 1.0 / 2.2)
                    let sb = pow(Double(color.blue), 1.0 / 2.2)


                    Rectangle()
                        .fill(
                            Color(
                                red: sr,
                                green: sg,
                                blue: sb
                            )
                        )
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                }
            }
            .padding(4)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.black))
        .cornerRadius(12)
    }
}

struct JourneyPaletteRowView: View {
    let title: String
    let colors: [ColorJourneyRGB]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .bold()

            ColorGridView(colors: colors, columns: 6)
                .frame(maxHeight: 80)
        }
    }
}

struct BaseColorDemoView: View {
    let label: String
    let style: JourneyStyle
    let baseColor: ColorJourneyRGB

    var body: some View {
        let journey = ColorJourney(config: .singleAnchor(baseColor, style: style))
        let palette = journey.discrete(count: 6)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .bold()
                Spacer()
                Text(formatRGB(baseColor))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ColorGridView(colors: palette, columns: 6)
                .frame(maxHeight: 80)
        }
    }
}

struct AnchorJourneyDemoView: View {
    let title: String
    @Binding var color: Color

    private var anchorColorJourney: ColorJourneyRGB {
        color.toColorJourneyRGB(default: ColorJourneyRGB(red: 0.8, green: 0.3, blue: 0.6))
    }

    var body: some View {
        let journey = ColorJourney(config: .singleAnchor(anchorColorJourney, style: .balanced))
        let palette = journey.discrete(count: 8)

        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            HStack {
                ColorPicker("Anchor", selection: $color)
                    .labelsHidden()
                Spacer()
                Text(formatRGB(anchorColorJourney))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ColorGridView(colors: palette, columns: 8)
                .frame(maxHeight: 120)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Main View

struct JourneyStylesView: View {
    // Anchor colors (editable via color pickers)
    @State private var anchorAColor: Color = Color(red: 0.8, green: 0.3, blue: 0.6)
    @State private var anchorBColor: Color = Color(red: 0.3, green: 0.6, blue: 0.9)
    @State private var anchorCColor: Color = Color(red: 0.2, green: 0.8, blue: 0.5)

    // Custom style dropdown labels (UI only; style mapping can be wired later)
    @State private var selectedLightness: String = "Lighter"
    @State private var selectedChroma: String = "Vivid"
    @State private var selectedContrast: String = "High"
    @State private var selectedTemperature: String = "Warm"

    /// The primary base color used for style demonstrations (maps to Anchor A).
    private var baseColor: ColorJourneyRGB {
        anchorAColor.toColorJourneyRGB(default: ColorJourneyRGB(red: 0.8, green: 0.3, blue: 0.6))
    }

    private let styles: [(name: String, style: JourneyStyle, description: String)] = [
        ("Balanced", .balanced, "Neutral on all dimensions. Safe, versatile default."),
        ("Pastel Drift", .pastelDrift, "Light, muted, soft contrast. Soft and sophisticated."),
        ("Vivid Loop", .vividLoop, "Saturated, high-contrast, seamless loop for color wheels."),
        ("Night Mode", .nightMode, "Dark, subdued colors. Ideal for dark UIs."),
        ("Warm Earth", .warmEarth, "Warm hues with natural, earthy character."),
        ("Cool Sky", .coolSky, "Cool hues, light and airy. Professional, calm.")
    ]

    private var customStyle: JourneyStyle {
        JourneyStyle.custom(
            lightness: .lighter,
            chroma: .vivid,
            contrast: .high,
            temperature: .warm
        )
    }

    var body: some View {
        let anchorA = anchorAColor.toColorJourneyRGB(default: ColorJourneyRGB(red: 0.8, green: 0.3, blue: 0.6))
        let anchorB = anchorBColor.toColorJourneyRGB(default: ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.9))
        let anchorC = anchorCColor.toColorJourneyRGB(default: ColorJourneyRGB(red: 0.2, green: 0.8, blue: 0.5))

        return VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Journey Styles")
                    .font(.largeTitle)
                    .bold()
                Text("Explore all 6 pre-configured journey styles using the same base color.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Base color: \(formatRGB(baseColor))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Anchor color pickers
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Anchor A")
                        .font(.caption)
                    ColorPicker("Anchor A", selection: $anchorAColor)
                        .labelsHidden()
                }
                VStack(alignment: .leading) {
                    Text("Anchor B")
                        .font(.caption)
                    ColorPicker("Anchor B", selection: $anchorBColor)
                        .labelsHidden()
                }
                VStack(alignment: .leading) {
                    Text("Anchor C")
                        .font(.caption)
                    ColorPicker("Anchor C", selection: $anchorCColor)
                        .labelsHidden()
                }
            }

            // 1. Journeys by Anchor Count
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Journeys by Anchor Count")
                    .font(.title2)
                    .bold()

                Text("Balanced default journeys driven by one, two, or three anchors. Adjust the anchors above to see how the palettes respond.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                // One anchor: use Anchor A
                do {
                    let journey = ColorJourney(config: .singleAnchor(anchorA, style: .balanced))
                    let colors = journey.discrete(count: 8)
                    JourneyStyleCardView(
                        title: "One anchor",
                        description: "Single-anchor journey based on Anchor A using balanced defaults.",
                        colors: colors
                    )
                }

                // Two anchors: use Anchor B as representative second anchor
                do {
                    let journey = ColorJourney(config: .singleAnchor(anchorB, style: .balanced))
                    let colors = journey.discrete(count: 8)
                    JourneyStyleCardView(
                        title: "Two anchors",
                        description: "Balanced journey using Anchor B as an example second anchor.",
                        colors: colors
                    )
                }

                // Three anchors: use Anchor C as representative third anchor
                do {
                    let journey = ColorJourney(config: .singleAnchor(anchorC, style: .balanced))
                    let colors = journey.discrete(count: 8)
                    JourneyStyleCardView(
                        title: "Three anchors",
                        description: "Balanced journey using Anchor C as an example third anchor.",
                        colors: colors
                    )
                }
            }

            // 2. Styles by Anchor Count
            VStack(alignment: .leading, spacing: 12) {
                Text("2. Styles by Anchor Count")
                    .font(.title2)
                    .bold()

                Text("For each of the one, two, and three anchor examples above, compare all pre-configured styles using the same anchor-derived base color.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                let anchorConfigs: [(label: String, color: ColorJourneyRGB)] = [
                    (label: "One anchor", color: anchorA),
                    (label: "Two anchors", color: anchorB),
                    (label: "Three anchors", color: anchorC)
                ]

                ForEach(0..<anchorConfigs.count, id: \.self) { anchorIndex in
                    let anchorInfo = anchorConfigs[anchorIndex]

                    VStack(alignment: .leading, spacing: 12) {
                        Text(anchorInfo.label)
                            .font(.title3)
                            .bold()

                        ForEach(0..<styles.count, id: \.self) { styleIndex in
                            let info = styles[styleIndex]
                            let journey = ColorJourney(config: .singleAnchor(anchorInfo.color, style: info.style))
                            let colors = journey.discrete(count: 8)

                            JourneyStyleCardView(
                                title: "\(info.name) (\(anchorInfo.label))",
                                description: info.description,
                                colors: colors
                            )

                        }
                    }
                }
            }

            // 3. Custom Style Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("3. Custom Style Configuration")
                    .font(.title2)
                    .bold()

                Text("Custom style: \(selectedLightness) + \(selectedChroma) + \(selectedContrast) + \(selectedTemperature)")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                // Dropdown controls for each part of the custom style
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Lightness", selection: $selectedLightness) {
                        Text("Darker").tag("Darker")
                        Text("Neutral").tag("Neutral")
                        Text("Lighter").tag("Lighter")
                    }
                    .pickerStyle(.menu)

                    Picker("Chroma", selection: $selectedChroma) {
                        Text("Muted").tag("Muted")
                        Text("Natural").tag("Natural")
                        Text("Vivid").tag("Vivid")
                    }
                    .pickerStyle(.menu)

                    Picker("Contrast", selection: $selectedContrast) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                    }
                    .pickerStyle(.menu)

                    Picker("Temperature", selection: $selectedTemperature) {
                        Text("Cool").tag("Cool")
                        Text("Neutral").tag("Neutral")
                        Text("Warm").tag("Warm")
                    }
                    .pickerStyle(.menu)
                }

                let customJourney = ColorJourney(config: .singleAnchor(baseColor, style: customStyle))
                let customColors = customJourney.discrete(count: 8)

                JourneyStyleCardView(
                    title: "Custom Style",
                    description: "Lighter + Vivid + High Contrast + Warm",
                    colors: customColors
                )
            }

            // Key Points
            VStack(alignment: .leading, spacing: 4) {
                Text("Key Points")
                    .font(.title3)
                    .bold()
                Text("• 6 pre-configured styles for common use cases")
                Text("• Each style combines lightness, chroma, contrast, and temperature biases")
                Text("• Use .custom() to create your own style combinations")
                Text("• Same style with different base colors produces related but distinct palettes")
            }

            .padding()
        }
    }
}

// Set the live view for the playground
PlaygroundPage.current.setLiveView(JourneyStylesView())

// MARK: - Color Conversion Helpers

extension Color {
    /// Convert a SwiftUI Color to ColorJourneyRGB in sRGB space.
    /// Falls back to the provided default if conversion fails.
    func toColorJourneyRGB(default defaultValue: ColorJourneyRGB) -> ColorJourneyRGB {
#if os(macOS)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return defaultValue
        }
        return ColorJourneyRGB(
            red: Float(rgbColor.redComponent),
            green: Float(rgbColor.greenComponent),
            blue: Float(rgbColor.blueComponent)
        )
#else
        return defaultValue
#endif
    }
}

/*:
 ---

 ## Summary

 You've explored:
 - All 6 pre-configured journey styles
 - Side-by-side comparison of styles
 - How base color affects the final palette
 - Creating custom style configurations

 **Recommendations:**
 - Use `.balanced` as a safe default
 - Use `.pastelDrift` for soft, sophisticated UIs
 - Use `.vividLoop` for data visualization and vibrant designs
 - Use `.nightMode` for dark mode interfaces
 - Use `.warmEarth` or `.coolSky` for themed designs

 **Next:** Learn about access patterns and incremental color generation →

 [Previous: Color Basics](@previous) | [Next: Access Patterns](@next)
 */
