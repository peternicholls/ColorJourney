import ColorJourney

// MARK: - Example 1: Simple Single-Anchor Journey

let blueColor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
let journey1 = ColorJourney(config: .singleAnchor(blueColor, style: .balanced))

// Sample at specific points
let color1 = journey1.sample(at: 0.0)
let color2 = journey1.sample(at: 0.5)
let color3 = journey1.sample(at: 1.0)

print("Single-Anchor Journey (Balanced):")
let c1Str = "RGB(\(String(format: "%.2f", color1.red)), \(String(format: "%.2f", color1.green)), \(String(format: "%.2f", color1.blue)))"
let c2Str = "RGB(\(String(format: "%.2f", color2.red)), \(String(format: "%.2f", color2.green)), \(String(format: "%.2f", color2.blue)))"
let c3Str = "RGB(\(String(format: "%.2f", color3.red)), \(String(format: "%.2f", color3.green)), \(String(format: "%.2f", color3.blue)))"
print("  Start:  \(c1Str)")
print("  Middle: \(c2Str)")
print("  End:    \(c3Str)")
print()

// MARK: - Example 2: Discrete Palette Generation

let palette = journey1.discrete(count: 5)
print("Discrete Palette (5 colors):")
for (index, color) in palette.enumerated() {
    print("  Color \(index + 1): RGB(\(String(format: "%.2f", color.red)), \(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))")
}
print()

// MARK: - Example 3: Multi-Anchor Journey

let red = ColorJourneyRGB(red: 1.0, green: 0.3, blue: 0.3)
let green = ColorJourneyRGB(red: 0.3, green: 1.0, blue: 0.3)
let blue = ColorJourneyRGB(red: 0.3, green: 0.3, blue: 1.0)

var multiConfig = ColorJourneyConfig.multiAnchor([red, green, blue], style: .balanced)
multiConfig.loopMode = .closed  // Close the loop
let journey2 = ColorJourney(config: multiConfig)

let multiPalette = journey2.discrete(count: 7)
print("Multi-Anchor Journey (Red → Green → Blue, Closed Loop):")
for (index, color) in multiPalette.enumerated() {
    print("  Color \(index + 1): RGB(\(String(format: "%.2f", color.red)), \(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))")
}
print()

// MARK: - Example 4: Styled Journey

let baseColor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.7)

print("Different Styles (10 colors each):")
let styles: [(name: String, style: JourneyStyle)] = [
    ("Pastel Drift", .pastelDrift),
    ("Vivid Loop", .vividLoop),
    ("Night Mode", .nightMode),
    ("Warm Earth", .warmEarth),
    ("Cool Sky", .coolSky)
]

for (styleName, style) in styles {
    let config = ColorJourneyConfig.singleAnchor(baseColor, style: style)
    let styledJourney = ColorJourney(config: config)
    let styledPalette = styledJourney.discrete(count: 3)
    print("  \(styleName): \(styledPalette.count) colors generated")
}
print()

// MARK: - Example 5: Journey with Variation

var configWithVariation = ColorJourneyConfig(anchors: [blueColor])
configWithVariation.variation = .subtle(dimensions: [.hue, .lightness], seed: 42)
let journey3 = ColorJourney(config: configWithVariation)

let variedPalette = journey3.discrete(count: 5)
print("Journey with Subtle Variation (deterministic seed):")
print("  Generated \(variedPalette.count) colors with hue and lightness variation")
print()

// MARK: - Example 6: Perceptual Dynamics

var dynamicConfig = ColorJourneyConfig(anchors: [blueColor])
dynamicConfig.lightness = .lighter
dynamicConfig.chroma = .vivid
dynamicConfig.contrast = .high
dynamicConfig.midJourneyVibrancy = 0.7

let dynamicJourney = ColorJourney(config: dynamicConfig)
let dynamicPalette = dynamicJourney.discrete(count: 5)

print("Journey with Enhanced Dynamics:")
print("  Lightness: Lighter")
print("  Chroma: Vivid")
print("  Contrast: High")
print("  Mid-journey Vibrancy: 0.7")
print("  Generated \(dynamicPalette.count) colors")
