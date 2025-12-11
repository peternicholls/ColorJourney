/*:
 [Previous: Access Patterns](@previous) | [Next: Advanced Use Cases](@next)
 
 # Configuration
 
 Deep dive into ColorJourney configuration options.
 
 ColorJourney provides extensive customization through perceptual biases and configuration options.
 Learn how to fine-tune palettes for your specific needs.
 */

import Foundation
import ColorJourney

print(separator())
print("CONFIGURATION - Customizing Your Journey")
print(separator())

//: ## 1. Anchor Colors
//: The foundation of any journey

print("\n📌 Anchor Colors")
print(dash())

// Single anchor - rotates around hue wheel
let singleAnchor = ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.9)
let singleJourney = ColorJourney(config: .singleAnchor(singleAnchor))
print("\nSingle anchor (rotates around hue wheel):")
print("Base: ", terminator: "")
displayColor(singleAnchor)
print("Palette:")
displayColorRow(singleJourney.discrete(count: 8))

// Multi-anchor - interpolates between colors
let red = ColorJourneyRGB(red: 0.9, green: 0.3, blue: 0.3)
let yellow = ColorJourneyRGB(red: 0.9, green: 0.9, blue: 0.3)
let green = ColorJourneyRGB(red: 0.3, green: 0.8, blue: 0.4)
let multiJourney = ColorJourney(config: .multiAnchor([red, yellow, green]))
print("\nMulti-anchor (interpolates between colors):")
print("Anchors: Red → Yellow → Green")
displayColorRow(multiJourney.discrete(count: 8))

//: ## 2. Lightness Bias
//: Adjust overall brightness

print("\n📌 Lightness Bias")
print(dash())

let baseColor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.8)
print("\nBase color: \(formatRGB(baseColor))\n")

let lightnessVariants = [
    ("Darker", LightnessBias.darker),
    ("Neutral", LightnessBias.neutral),
    ("Lighter", LightnessBias.lighter)
]

for (name, bias) in lightnessVariants {
    var config = ColorJourneyConfig(anchors: [baseColor])
    config.lightness = bias
    let journey = ColorJourney(config: config)
    let colors = journey.discrete(count: 6)
    print("\(name.padding(toLength: 10, withPad: " ", startingAt: 0))", terminator: "")
    displayColorRow(colors)
}

//: ## 3. Chroma Bias
//: Adjust saturation intensity

print("\n📌 Chroma Bias (Saturation)")
print(dash())

let chromaVariants = [
    ("Muted", ChromaBias.muted),
    ("Neutral", ChromaBias.neutral),
    ("Vivid", ChromaBias.vivid)
]

for (name, bias) in chromaVariants {
    var config = ColorJourneyConfig(anchors: [baseColor])
    config.chroma = bias
    let journey = ColorJourney(config: config)
    let colors = journey.discrete(count: 6)
    print("\(name.padding(toLength: 10, withPad: " ", startingAt: 0))", terminator: "")
    displayColorRow(colors)
}

//: ## 4. Contrast Level
//: Minimum perceptual distance between colors

print("\n📌 Contrast Level")
print(dash())

let contrastVariants = [
    ("Low", ContrastLevel.low),
    ("Medium", ContrastLevel.medium),
    ("High", ContrastLevel.high)
]

for (name, level) in contrastVariants {
    var config = ColorJourneyConfig(anchors: [baseColor])
    config.contrast = level
    let journey = ColorJourney(config: config)
    let colors = journey.discrete(count: 6)
    print("\(name.padding(toLength: 10, withPad: " ", startingAt: 0))", terminator: "")
    displayColorRow(colors)
}

print("\n   💡 Higher contrast = more distinct colors (better accessibility)")

//: ## 5. Temperature Bias
//: Shift hue toward warm or cool tones

print("\n📌 Temperature Bias")
print(dash())

let tempVariants = [
    ("Cool", TemperatureBias.cool),
    ("Neutral", TemperatureBias.neutral),
    ("Warm", TemperatureBias.warm)
]

for (name, temp) in tempVariants {
    var config = ColorJourneyConfig(anchors: [baseColor])
    config.temperature = temp
    let journey = ColorJourney(config: config)
    let colors = journey.discrete(count: 6)
    print("\(name.padding(toLength: 10, withPad: " ", startingAt: 0))", terminator: "")
    displayColorRow(colors)
}

//: ## 6. Loop Mode
//: Control boundary behavior

print("\n📌 Loop Mode")
print(dash())

let loopModes: [(String, LoopMode, String)] = [
    ("Open", .open, "One-way journey (clamped at boundaries)"),
    ("Closed", .closed, "Seamless loop (wraps around)"),
    ("Ping-Pong", .pingPong, "Reverses at boundaries")
]

for (name, mode, description) in loopModes {
    var config = ColorJourneyConfig(anchors: [baseColor])
    config.loopMode = mode
    let journey = ColorJourney(config: config)
    
    print("\n\(name): \(description)")
    // Sample beyond [0, 1] to show wrapping behavior
    let samples = [-0.2, 0.0, 0.5, 1.0, 1.2].map { journey.sample(at: Float($0)) }
    print("  Samples at t = -0.2, 0.0, 0.5, 1.0, 1.2:")
    displayColorRow(samples)
}

//: ## 7. Mid-Journey Vibrancy
//: Energy/variation at journey center

print("\n📌 Mid-Journey Vibrancy")
print(dash())

let vibrancyLevels: [(String, Float)] = [
    ("Low (0.1)", 0.1),
    ("Medium (0.3)", 0.3),
    ("High (0.7)", 0.7)
]

for (name, vibrancy) in vibrancyLevels {
    var config = ColorJourneyConfig(anchors: [baseColor])
    config.midJourneyVibrancy = vibrancy
    let journey = ColorJourney(config: config)
    let colors = journey.discrete(count: 6)
    print("\(name.padding(toLength: 15, withPad: " ", startingAt: 0))", terminator: "")
    displayColorRow(colors)
}

//: ## 8. Variation
//: Deterministic micro-changes for organic appearance

print("\n📌 Variation (Deterministic Randomness)")
print(dash())

let noVariation = ColorJourneyConfig(
    anchors: [baseColor],
    variation: .off
)
let withVariation = ColorJourneyConfig(
    anchors: [baseColor],
    variation: .subtle(dimensions: [.hue, .lightness], seed: 42)
)

print("\nWithout variation:")
let journey1 = ColorJourney(config: noVariation)
displayColorRow(journey1.discrete(count: 8))

print("\nWith subtle variation (hue + lightness):")
let journey2 = ColorJourney(config: withVariation)
displayColorRow(journey2.discrete(count: 8))

print("\n   💡 Same config + same seed = reproducible variation")

//: ## 9. Combined Configuration
//: Putting it all together

print("\n" + separator())
print("COMBINED CONFIGURATION EXAMPLE")
print(separator())

let customConfig = ColorJourneyConfig(
    anchors: [ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.9)],
    lightness: .lighter,
    chroma: .vivid,
    contrast: .high,
    midJourneyVibrancy: 0.5,
    temperature: .cool,
    loopMode: .closed,
    variation: .subtle(dimensions: [.hue], seed: 12345)
)

print("\nCustom configuration:")
print("  • Lightness: Lighter")
print("  • Chroma: Vivid")
print("  • Contrast: High")
print("  • Mid-journey vibrancy: 0.5")
print("  • Temperature: Cool")
print("  • Loop mode: Closed")
print("  • Variation: Subtle (hue only)")
print("\nResulting palette:")

let customJourney = ColorJourney(config: customConfig)
displayColorRow(customJourney.discrete(count: 10))

print("\n💡 Key Points:")
print("   • All configuration options are independent")
print("   • Combine options to achieve desired aesthetic")
print("   • Use preset styles as starting points, then customize")
print("   • Variation adds organic feel while remaining deterministic")
print("   • Higher contrast improves accessibility")

print("\n" + separator())

/*:
 ---
 
 ## Summary
 
 You've explored:
 - Anchor colors (single vs multi)
 - Lightness bias (darker, neutral, lighter)
 - Chroma bias (muted, neutral, vivid)
 - Contrast levels (low, medium, high)
 - Temperature bias (cool, neutral, warm)
 - Loop modes (open, closed, ping-pong)
 - Mid-journey vibrancy
 - Variation for organic appearance
 - Combined configurations
 
 **Recommendations:**
 - Start with a preset style, then customize as needed
 - Use high contrast for accessibility-critical UIs
 - Use variation sparingly (subtle is usually best)
 - Closed loop mode works well for circular UI elements
 - Lighter bias for light themes, darker for dark themes
 
 **Next:** See real-world examples and advanced use cases →
 
 [Previous: Access Patterns](@previous) | [Next: Advanced Use Cases](@next)
 */
