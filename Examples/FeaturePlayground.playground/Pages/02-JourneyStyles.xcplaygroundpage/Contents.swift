/*:
 [Previous: Color Basics](@previous) | [Next: Access Patterns](@next)
 
 # Journey Styles
 
 Explore all 6 pre-configured journey styles.
 
 Each style is a preset combination of perceptual biases (lightness, chroma, contrast, temperature)
 optimized for common use cases. Use these as-is or as starting points for customization.
 */

import Foundation
import ColorJourney

print(separator())
print("JOURNEY STYLES - Pre-configured Palettes")
print(separator())

//: ## All 6 Journey Styles
//: Let's generate a palette from each style using the same base color

let baseColor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
print("\nBase color for all styles: \(formatRGB(baseColor))")
print("Generating 8 colors per style:\n")

let styles: [(String, JourneyStyle, String)] = [
    ("Balanced", .balanced, "Neutral on all dimensions. Safe, versatile default."),
    ("Pastel Drift", .pastelDrift, "Light, muted, soft contrast. Soft and sophisticated."),
    ("Vivid Loop", .vividLoop, "Saturated, high-contrast, seamless loop for color wheels."),
    ("Night Mode", .nightMode, "Dark, subdued colors. Ideal for dark UIs."),
    ("Warm Earth", .warmEarth, "Warm hues with natural, earthy character."),
    ("Cool Sky", .coolSky, "Cool hues, light and airy. Professional, calm.")
]

for (name, style, description) in styles {
    print("\n\(name)")
    print(dash())
    print("  \(description)")
    
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: style))
    let colors = journey.discrete(count: 8)
    
    print("  Palette:")
    displayColorRow(colors)
}

//: ## Side-by-Side Comparison
//: Generate the same 6-color palette from each style for easy comparison

print("\n" + separator())
print("SIDE-BY-SIDE COMPARISON (6 colors each)")
print(separator() + "\n")

for (name, style, _) in styles {
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: style))
    let colors = journey.discrete(count: 6)
    
    print("\(name.padding(toLength: 15, withPad: " ", startingAt: 0))", terminator: "")
    for color in colors {
        let ansi = ANSIColor(from: color)
        print(ansi.swatch(), terminator: " ")
    }
    print()
}

//: ## Different Base Colors
//: Same style, different base color shows versatility

print("\n" + separator())
print("STYLE WITH DIFFERENT BASE COLORS")
print(separator())

let baseColors = [
    ("Blue", ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.9)),
    ("Green", ColorJourneyRGB(red: 0.3, green: 0.8, blue: 0.4)),
    ("Purple", ColorJourneyRGB(red: 0.6, green: 0.3, blue: 0.8))
]

print("\nUsing 'Vivid Loop' style with different base colors:\n")

for (name, color) in baseColors {
    print("\(name) base:")
    let journey = ColorJourney(config: .singleAnchor(color, style: .vividLoop))
    let palette = journey.discrete(count: 6)
    displayColorRow(palette)
}

//: ## Custom Style Configuration
//: You can also create custom styles

print("\n" + separator())
print("CUSTOM STYLE CONFIGURATION")
print(separator())

let customStyle = JourneyStyle.custom(
    lightness: .lighter,
    chroma: .vivid,
    contrast: .high,
    temperature: .warm
)

print("\nCustom style: Lighter + Vivid + High Contrast + Warm")
let customJourney = ColorJourney(config: .singleAnchor(baseColor, style: customStyle))
let customColors = customJourney.discrete(count: 8)
displayColorRow(customColors)

print("\n💡 Key Points:")
print("   • 6 pre-configured styles for common use cases")
print("   • Each style combines lightness, chroma, contrast, and temperature biases")
print("   • Use .custom() to create your own style combinations")
print("   • Same style with different base colors produces related but distinct palettes")

print("\n" + separator())

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
