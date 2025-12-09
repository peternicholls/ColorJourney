/*:
 [Previous: Introduction](@previous) | [Next: Journey Styles](@next)
 
 # Color Basics
 
 Explore the `ColorJourneyRGB` type and color fundamentals.
 
 ColorJourney uses linear sRGB color space with floating-point components [0, 1].
 This provides high precision and easy conversion to platform-specific formats.
 */

import Foundation
import ColorJourney

print(separator())
print("COLOR BASICS - ColorJourneyRGB Type")
print(separator())

//: ## 1. Creating Colors

print("\n📌 Creating Colors")
print(dash())

// Basic RGB initialization
let red = ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0)
let green = ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0)
let blue = ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)

displayColor(red, label: "Pure Red")
displayColor(green, label: "Pure Green")
displayColor(blue, label: "Pure Blue")

// Mixed colors
let purple = ColorJourneyRGB(red: 0.5, green: 0.0, blue: 0.8)
let orange = ColorJourneyRGB(red: 1.0, green: 0.6, blue: 0.2)
let teal = ColorJourneyRGB(red: 0.2, green: 0.8, blue: 0.7)

print("\nMixed Colors:")
displayColor(purple, label: "Purple")
displayColor(orange, label: "Orange")
displayColor(teal, label: "Teal")

//: ## 2. Color Components

print("\n📌 Accessing Color Components")
print(dash())

let testColor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.9)
print("Color components:")
print("  red:   \(testColor.red)")
print("  green: \(testColor.green)")
print("  blue:  \(testColor.blue)")

//: ## 3. Grayscale Colors

print("\n📌 Grayscale Colors (equal RGB components)")
print(dash())

let black = ColorJourneyRGB(red: 0.0, green: 0.0, blue: 0.0)
let darkGray = ColorJourneyRGB(red: 0.25, green: 0.25, blue: 0.25)
let gray = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
let lightGray = ColorJourneyRGB(red: 0.75, green: 0.75, blue: 0.75)
let white = ColorJourneyRGB(red: 1.0, green: 1.0, blue: 1.0)

let grayscale = [black, darkGray, gray, lightGray, white]
print("Grayscale progression:")
displayColorRow(grayscale)

//: ## 4. Color Equality

print("\n📌 Color Equality")
print(dash())

let color1 = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
let color2 = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
let color3 = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.81)

print("color1: \(formatRGB(color1))")
print("color2: \(formatRGB(color2))")
print("color3: \(formatRGB(color3))")
print("\ncolor1 == color2: \(color1 == color2)")
print("color1 == color3: \(color1 == color3)")
print("colorsEqual(color1, color3, tolerance: 0.1): \(colorsEqual(color1, color3, tolerance: 0.1))")

//: ## 5. Sample Palette

print("\n📌 Sample Color Palette")
print(dash())

let palette = [
    ColorJourneyRGB(red: 0.9, green: 0.2, blue: 0.3),  // Red
    ColorJourneyRGB(red: 0.95, green: 0.6, blue: 0.2), // Orange
    ColorJourneyRGB(red: 0.95, green: 0.9, blue: 0.3), // Yellow
    ColorJourneyRGB(red: 0.3, green: 0.8, blue: 0.4),  // Green
    ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.9),  // Blue
    ColorJourneyRGB(red: 0.6, green: 0.3, blue: 0.8),  // Purple
]

print("Rainbow palette (6 colors):")
displayColorRow(palette)

print("\n💡 Key Points:")
print("   • ColorJourneyRGB uses linear sRGB with components [0, 1]")
print("   • Float precision for high-quality color manipulation")
print("   • Hashable - can be used in Sets and Dictionary keys")
print("   • Platform conversions available (SwiftUI Color, UIColor, NSColor)")

print("\n" + separator())

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
