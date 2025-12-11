/*:
 [Previous: Introduction](@previous) | [Next: Journey Styles](@next)

 # Color Basics

 Explore the `ColorJourneyRGB` type and color fundamentals.

 ColorJourney uses linear sRGB color space with floating-point components [0, 1].
 This provides high precision and easy conversion to platform-specific formats.
 */

import SwiftUI
import PlaygroundSupport
import ColorJourney

// MARK: - SwiftUI Helpers

/// Basic color swatch with label and RGB values.
struct ColorSwatchView: View {
    let title: String
    let color: ColorJourneyRGB

    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(
                    red: Double(color.red),
                    green: Double(color.green),
                    blue: Double(color.blue)
                ))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .shadow(radius: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(formatRGB(color))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// A simple row of color swatches.
struct ColorRowView: View {
    let title: String
    let colors: [(String, ColorJourneyRGB)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<colors.count, id: \.self) { index in
                        let item = colors[index]
                        VStack {
                            Rectangle()
                                .fill(Color(
                                    red: Double(item.1.red),
                                    green: Double(item.1.green),
                                    blue: Double(item.1.blue)
                                ))
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .shadow(radius: 1)

                            Text(item.0)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Main View

struct ColorBasicsView: View {
    // 1. Creating Colors
    private let red = ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0)
    private let green = ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0)
    private let blue = ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)

    private let purple = ColorJourneyRGB(red: 0.5, green: 0.0, blue: 0.8)
    private let orange = ColorJourneyRGB(red: 1.0, green: 0.6, blue: 0.2)
    private let teal = ColorJourneyRGB(red: 0.2, green: 0.8, blue: 0.7)

    // 2. Color Components (interactive)
    @State private var testRed: Double = 0.3
    @State private var testGreen: Double = 0.6
    @State private var testBlue: Double = 0.9

    private var testColor: ColorJourneyRGB {
        ColorJourneyRGB(red: Float(testRed), green: Float(testGreen), blue: Float(testBlue))
    }

    // 3. Grayscale
    private let grayscale: [ColorJourneyRGB] = [
        ColorJourneyRGB(red: 0.0, green: 0.0, blue: 0.0),
        ColorJourneyRGB(red: 0.25, green: 0.25, blue: 0.25),
        ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5),
        ColorJourneyRGB(red: 0.75, green: 0.75, blue: 0.75),
        ColorJourneyRGB(red: 1.0, green: 1.0, blue: 1.0)
    ]

    // 5. Sample palette
    private let palette: [ColorJourneyRGB] = [
        ColorJourneyRGB(red: 0.9, green: 0.2, blue: 0.3),  // Red
        ColorJourneyRGB(red: 0.95, green: 0.6, blue: 0.2), // Orange
        ColorJourneyRGB(red: 0.95, green: 0.9, blue: 0.3), // Yellow
        ColorJourneyRGB(red: 0.3, green: 0.8, blue: 0.4),  // Green
        ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.9),  // Blue
        ColorJourneyRGB(red: 0.6, green: 0.3, blue: 0.8)   // Purple
    ]

    var body: some View {

            VStack(alignment: .leading, spacing: 24) {
                Text("COLOR BASICS - ColorJourneyRGB")
                    .font(.largeTitle)
                    .bold()

                Text("ColorJourney uses linear sRGB with floating-point components [0, 1].")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // 1. Creating Colors
                ColorRowView(
                    title: "1. Creating Colors",
                    colors: [
                        ("Red", red),
                        ("Green", green),
                        ("Blue", blue),
                        ("Purple", purple),
                        ("Orange", orange),
                        ("Teal", teal)
                    ]
                )

                // 2. Color Components
                VStack(alignment: .leading, spacing: 8) {
                    Text("2. Color Components")
                        .font(.title3)
                        .bold()

                    ColorSwatchView(title: "Test Color", color: testColor)

                    HStack(spacing: 16) {
                        componentView(name: "Red", value: testRed)
                        componentView(name: "Green", value: testGreen)
                        componentView(name: "Blue", value: testBlue)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adjust Components")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        componentSlider(name: "Red", value: $testRed)
                        componentSlider(name: "Green", value: $testGreen)
                        componentSlider(name: "Blue", value: $testBlue)
                    }
                }

                // 3. Grayscale Colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("3. Grayscale Colors")
                        .font(.title3)
                        .bold()

                    ColorRowView(
                        title: "Grayscale progression",
                        colors: [
                            ("Black", grayscale[0]),
                            ("Dark Gray", grayscale[1]),
                            ("Gray", grayscale[2]),
                            ("Light Gray", grayscale[3]),
                            ("White", grayscale[4])
                        ]
                    )
                }

                // 4. Color Equality (visual)
                VStack(alignment: .leading, spacing: 8) {
                    Text("4. Color Equality")
                        .font(.title3)
                        .bold()

                    let color1 = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
                    let color2 = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
                    let color3 = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.81)

                    HStack(spacing: 16) {
                        ColorSwatchView(title: "Color 1", color: color1)
                        ColorSwatchView(title: "Color 2", color: color2)
                        ColorSwatchView(title: "Color 3", color: color3)
                    }

                    Text("Color 1 == Color 2: \(color1 == color2 ? "true" : "false")")
                    Text("Color 1 == Color 3: \(color1 == color3 ? "true" : "false")")
                    Text("Approx equal (tolerance 0.1): \(colorsEqual(color1, color3, tolerance: 0.1) ? "true" : "false")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 5. Sample Palette (grid)
                VStack(alignment: .leading, spacing: 8) {
                    Text("5. Sample Palette")
                        .font(.title3)
                        .bold()

                    Text("Rainbow palette (6 colors):")

                    // Use the helper from ColorUtilities.swift to show a grid in-place
                    ColorGridView(colors: palette, columns: 6)
                        .frame(maxHeight: 200)
                }

                // Key points
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Points")
                        .font(.title3)
                        .bold()
                    Text("• ColorJourneyRGB uses linear sRGB with components [0, 1]")
                    Text("• Float precision for high-quality color manipulation")
                    Text("• Hashable - can be used in Sets and Dictionary keys")
                    Text("• Platform conversions available (SwiftUI Color, UIColor, NSColor)")
                }
            
            .padding()
        }
    }

    private func componentView(name: String, value: Double) -> some View {
        VStack {
            Text(name)
                .font(.caption)
            Text(String(format: "%.2f", value))
                .bold()
        }
        .padding(8)
        .background(Color(.black))
        .cornerRadius(8)
    }

    private func componentSlider(name: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(name)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption)
                    .monospacedDigit()
            }
            Slider(value: value, in: 0...1)
        }
    }
}

// Set the live view for the playground
PlaygroundPage.current.setLiveView(ColorBasicsView())

/*:
 ---

 ## Summary

 You've learned:
 - How to create `ColorJourneyRGB` colors
 - Accessing color components
 - Creating grayscale colors
 - Comparing colors for equality
 - Building color palettes

 **Next:** Learn about pre-configured Journey Styles →

 [Previous: Introduction](@previous) | [Next: Journey Styles](@next)
 */
