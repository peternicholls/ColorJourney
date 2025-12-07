import ColorJourney

// MARK: - Example 1: Simple Single-Anchor Journey

let blueColor = ColorJourneyRGB(r: 0.3, g: 0.5, b: 0.8)
let journey1 = ColorJourney(config: .singleAnchor(blueColor, style: .balanced))

// Sample at specific points
let color1 = journey1.sample(at: 0.0)
let color2 = journey1.sample(at: 0.5)
let color3 = journey1.sample(at: 1.0)

print("Single-Anchor Journey (Balanced):")
print("  Start:  RGB(\(String(format: "%.2f", color1.r)), \(String(format: "%.2f", color1.g)), \(String(format: "%.2f", color1.b)))")
print("  Middle: RGB(\(String(format: "%.2f", color2.r)), \(String(format: "%.2f", color2.g)), \(String(format: "%.2f", color2.b)))")
print("  End:    RGB(\(String(format: "%.2f", color3.r)), \(String(format: "%.2f", color3.g)), \(String(format: "%.2f", color3.b)))")
print()

// MARK: - Example 2: Discrete Palette Generation

let palette = journey1.discrete(count: 5)
print("Discrete Palette (5 colors):")
for (i, color) in palette.enumerated() {
    print("  Color \(i + 1): RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
}
print()

// MARK: - Example 3: Multi-Anchor Journey

let red = ColorJourneyRGB(r: 1.0, g: 0.3, b: 0.3)
let green = ColorJourneyRGB(r: 0.3, g: 1.0, b: 0.3)
let blue = ColorJourneyRGB(r: 0.3, g: 0.3, b: 1.0)

var multiConfig = ColorJourneyConfig.multiAnchor([red, green, blue], style: .balanced)
multiConfig.loopMode = .closed  // Close the loop
let journey2 = ColorJourney(config: multiConfig)

let multiPalette = journey2.discrete(count: 7)
print("Multi-Anchor Journey (Red → Green → Blue, Closed Loop):")
for (i, color) in multiPalette.enumerated() {
    print("  Color \(i + 1): RGB(\(String(format: "%.2f", color.r)), \(String(format: "%.2f", color.g)), \(String(format: "%.2f", color.b)))")
}
print()

// MARK: - Example 4: Styled Journey

let baseColor = ColorJourneyRGB(r: 0.5, g: 0.3, b: 0.7)

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
