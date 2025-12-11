/*:
 [Previous: Configuration](@previous)
 
 # Advanced Use Cases
 
 Real-world examples and patterns from SwatchDemo.
 
 See how ColorJourney solves common color palette challenges in real applications.
 These examples are adapted from the SwatchDemo CLI tool.
 */

import Foundation
import ColorJourney

print(separator())
print("ADVANCED USE CASES - Real-World Examples")
print(separator())

//: ## 1. Progressive UI Building
//: User adds elements incrementally, each needs a color

print("\n🎯 Use Case 1: Progressive UI Building")
print(dash())
print("Scenario: Video timeline tracks added one at a time\n")

let baseColor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))

let trackNames = ["Background", "Foreground", "Lighting", "FX", "Audio"]

print("User Action → Color Assigned")
print(dash(60))

for (index, trackName) in trackNames.enumerated() {
    let color = journey[index]
    print("User creates track '\(trackName)'")
    print("  → Index: \(index)")
    print("  → ", terminator: "")
    displayColor(color)
    print()
}

print("💡 Pattern: Each track gets its color on-demand using subscript access")
print("   journey[0], journey[1], journey[2], etc.")

//: ## 2. Tag System
//: Initial batch, then incremental additions

print("\n\n🎯 Use Case 2: Tag System (Document Tags)")
print(dash())
print("Scenario: Document starts with 3 tags, user adds 2 more\n")

let tagColor = ColorJourneyRGB(red: 0.6, green: 0.3, blue: 0.7)
let tagConfig = ColorJourneyConfig(anchors: [tagColor], contrast: .high)
let tagJourney = ColorJourney(config: tagConfig)

print("Initial Tags (batch access):")
let initialTags = ["swift", "ios", "design"]
let initialColors = tagJourney.discrete(range: 0..<3)

for (tag, color) in zip(initialTags, initialColors) {
    let ansi = ANSIColor(from: color)
    print("\(ansi.swatch(width: 2))  #\(tag)")
}

print("\nUser adds tags (incremental access):")
let newTags = ["performance", "animation"]

for (offset, tag) in newTags.enumerated() {
    let index = 3 + offset
    let color = tagJourney[index]
    print("  → Adding '\(tag)' at index \(index)")
    print("     ", terminator: "")
    displayColor(color)
}

print("\n💡 Pattern: Mix of batch (discrete(range:)) + incremental (subscript)")

//: ## 3. Responsive Layout
//: Column count changes based on screen size

print("\n\n🎯 Use Case 3: Responsive Layout")
print(dash())
print("Scenario: Grid columns change with screen size\n")

let gridColor = ColorJourneyRGB(red: 0.2, green: 0.6, blue: 0.4)
let gridJourney = ColorJourney(config: .singleAnchor(gridColor, style: .vividLoop))

let scenarios = [
    ("Mobile (1 column)", 1),
    ("Tablet (2 columns)", 2),
    ("Desktop (4 columns)", 4),
    ("Ultra-wide (6 columns)", 6)
]

for (scenario, columnCount) in scenarios {
    print("\(scenario):")
    let colors = Array(gridJourney.discreteColors.prefix(columnCount))
    var line = "  "
    for color in colors {
        let ansi = ANSIColor(from: color)
        line += ansi.swatch(width: 6) + " "
    }
    print(line)
}

print("\n💡 Pattern: Lazy sequence for variable-size layouts")
print("   journey.discreteColors.prefix(columnCount)")

//: ## 4. Data Visualization
//: Charts with varying category counts

print("\n\n🎯 Use Case 4: Data Visualization")
print(dash())
print("Scenario: Charts need colors for N categories (N varies)\n")

let red = ColorJourneyRGB(red: 1.0, green: 0.3, blue: 0.3)
let green = ColorJourneyRGB(red: 0.3, green: 1.0, blue: 0.3)
let vizConfig = ColorJourneyConfig(
    anchors: [red, green],
    contrast: .high,
    loopMode: .closed
)
let vizJourney = ColorJourney(config: vizConfig)

let datasets = [
    ("Quarterly Results", 4),
    ("Monthly Breakdown", 12),
    ("Weekly Trends", 20)
]

for (chartName, categoryCount) in datasets {
    print("\(chartName) (\(categoryCount) categories):")
    let colors = vizJourney.discrete(range: 0..<categoryCount)
    
    // Display in rows of 10
    for chunk in colors.chunked(into: 10) {
        print("  ", terminator: "")
        displayColorRow(chunk)
    }
    print()
}

print("💡 Pattern: Batch range access for known category count")
print("   journey.discrete(range: 0..<categoryCount)")

//: ## 5. Continuous Sampling (Gradients)
//: Smooth transitions for animations and gradients

print("\n\n🎯 Use Case 5: Continuous Sampling (Gradients)")
print(dash())
print("Scenario: Create smooth gradient with 20 color stops\n")

let gradColor = ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)
let gradJourney = ColorJourney(config: .singleAnchor(gradColor, style: .balanced))

print("Gradient (20 stops sampled continuously):")
var gradientColors: [ColorJourneyRGB] = []
for i in 0..<20 {
    let t = Float(i) / 19.0
    gradientColors.append(gradJourney.sample(at: t))
}

displayColorRow(gradientColors)

print("\n💡 Pattern: Continuous sampling with sample(at:)")
print("   Use for smooth gradients, animations, transitions")

//: ## 6. Multi-Anchor Transitions
//: Controlled color transitions between specific colors

print("\n\n🎯 Use Case 6: Multi-Anchor Color Transitions")
print(dash())
print("Scenario: Transition through specific brand colors\n")

let brandRed = ColorJourneyRGB(red: 0.9, green: 0.2, blue: 0.3)
let brandYellow = ColorJourneyRGB(red: 0.95, green: 0.9, blue: 0.3)
let brandBlue = ColorJourneyRGB(red: 0.2, green: 0.4, blue: 0.9)

let brandJourney = ColorJourney(config: .multiAnchor([brandRed, brandYellow, brandBlue]))

print("Brand colors transition (Red → Yellow → Blue):")
let brandPalette = brandJourney.discrete(count: 12)
displayColorRow(brandPalette)

print("\n💡 Pattern: Multi-anchor for controlled color transitions")
print("   Colors interpolate smoothly between anchors")

//: ## 7. Accessibility-First Palettes
//: High contrast for better accessibility

print("\n\n🎯 Use Case 7: Accessibility-First Palettes")
print(dash())
print("Scenario: UI components need highly distinct colors\n")

let a11yColor = ColorJourneyRGB(red: 0.4, green: 0.4, blue: 0.8)
let a11yConfig = ColorJourneyConfig(
    anchors: [a11yColor],
    contrast: .high,
    midJourneyVibrancy: 0.5
)
let a11yJourney = ColorJourney(config: a11yConfig)

print("High-contrast palette (WCAG-friendly):")
let a11yPalette = a11yJourney.discrete(count: 8)
displayColorRow(a11yPalette)

print("\nCompare with low contrast:")
var lowContrastConfig = ColorJourneyConfig(anchors: [a11yColor])
lowContrastConfig.contrast = .low
let lowJourney = ColorJourney(config: lowContrastConfig)
displayColorRow(lowJourney.discrete(count: 8))

print("\n💡 Pattern: Use .high contrast for accessibility")
print("   Ensures colors are perceptually distinct")

//: ## 8. Dark Mode Palettes
//: Optimized colors for dark backgrounds

print("\n\n🎯 Use Case 8: Dark Mode Palettes")
print(dash())
print("Scenario: UI needs dark-friendly colors\n")

let darkColor = ColorJourneyRGB(red: 0.5, green: 0.6, blue: 0.7)

print("Light mode (default):")
let lightJourney = ColorJourney(config: .singleAnchor(darkColor, style: .balanced))
displayColorRow(lightJourney.discrete(count: 6))

print("\nDark mode (nightMode style):")
let darkJourney = ColorJourney(config: .singleAnchor(darkColor, style: .nightMode))
displayColorRow(darkJourney.discrete(count: 6))

print("\n💡 Pattern: Use .nightMode style for dark UIs")
print("   Colors are darker and more subdued")

//: ## Best Practices Summary

print("\n" + separator())
print("BEST PRACTICES")
print(separator())

print("""

✅ Progressive UI Building
   • Use subscript access: journey[i]
   • No need to know final count upfront

✅ Batch + Incremental Mix
   • Initial batch: discrete(range: 0..<N)
   • Later additions: journey[N], journey[N+1], ...

✅ Responsive Layouts
   • Use lazy sequence: discreteColors.prefix(N)
   • Adapts to changing sizes efficiently

✅ Data Visualization
   • Use discrete(range:) for known category counts
   • High contrast for distinguishability

✅ Gradients & Animations
   • Use sample(at: t) for continuous sampling
   • Smooth transitions between values

✅ Accessibility
   • Use .high contrast level
   • Test with color-blind simulators
   • Ensure WCAG compliance

✅ Dark Mode
   • Use .nightMode style or .darker lightness bias
   • Reduce saturation for dark backgrounds

✅ Brand Consistency
   • Use multi-anchor with brand colors
   • Smooth transitions between brand palette
""")

print("\n" + separator())

/*:
 ---
 
 ## Summary
 
 You've explored:
 - Progressive UI building (incremental access)
 - Tag systems (mixed batch + incremental)
 - Responsive layouts (lazy sequences)
 - Data visualization (batch ranges)
 - Continuous sampling (gradients)
 - Multi-anchor transitions (brand colors)
 - Accessibility-first palettes (high contrast)
 - Dark mode optimization (nightMode style)
 
 **Key Insight:** ColorJourney adapts to your access pattern.
 Choose the method that fits your use case naturally.
 
 ## What's Next?
 
 - Check out the SwatchDemo CLI tool for more examples
 - Read the API documentation for detailed parameter explanations
 - Experiment with custom configurations
 - Build your own color-critical applications!
 
 **Resources:**
 - [ColorJourney README](../../README.md)
 - [SwatchDemo Source](../../Examples/SwatchDemo/)
 - [API Documentation](../../Docs/)
 
 [Previous: Configuration](@previous)
 */
