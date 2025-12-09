/*
 * Docstring Code Snippet Validation
 * ==================================
 *
 * This file validates that all code snippets in the Swift API documentation
 * compile and run correctly. Each function below corresponds to a code snippet
 * extracted from doc comments in Sources/ColorJourney/ColorJourney.swift.
 *
 * User Story US5: Code snippets from docstrings are verified compilable.
 * This ensures developers can copy-paste examples and expect them to work.
 */

import Foundation
import ColorJourney

// MARK: - Docstring Snippet 1: Basic Single Anchor Config
func testDocSnippet_BasicSingleAnchorConfig() {
    /* From ColorJourneyConfig documentation */
    let config = ColorJourneyConfig.singleAnchor(
        ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8),
        style: .balanced
    )
    let journey = ColorJourney(config: config)
    let palette = journey.discrete(count: 3)
    assert(palette.count == 3, "Basic config failed")
    print("✓ Snippet 1: Basic single anchor config compiles")
}

// MARK: - Docstring Snippet 2: Advanced Config
func testDocSnippet_AdvancedConfig() {
    /* From ColorJourneyConfig documentation */
    let color1 = ColorJourneyRGB(red: 0.8, green: 0.3, blue: 0.2)
    let color2 = ColorJourneyRGB(red: 0.2, green: 0.8, blue: 0.3)
    
    let config = ColorJourneyConfig(
        anchors: [color1, color2],
        lightness: .lighter,
        chroma: .vivid,
        contrast: .high,
        temperature: .warm,
        variation: .subtle(dimensions: [.hue, .lightness])
    )
    let journey = ColorJourney(config: config)
    let palette = journey.discrete(count: 5)
    assert(palette.count == 5, "Advanced config failed")
    print("✓ Snippet 2: Advanced config compiles")
}

// MARK: - Docstring Snippet 3: Constructor Example
func testDocSnippet_ConstructorExample() {
    /* From ColorJourney init documentation */
    let config = ColorJourneyConfig(
        anchors: [ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)],
        lightness: .lighter,
        chroma: .vivid,
        contrast: .high
    )
    let journey = ColorJourney(config: config)
    let color = journey.sample(at: 0.5)
    assert(color.red >= 0.0 && color.red <= 1.0, "Constructor example failed")
    print("✓ Snippet 3: Constructor example compiles")
}

// MARK: - Docstring Snippet 4: Smooth Gradient (sample method)
func testDocSnippet_SmoothGradient() {
    /* From sample() method documentation */
    let journey = ColorJourney(config: .singleAnchor(
        ColorJourneyRGB(red: 0.4, green: 0.5, blue: 0.9),
        style: .balanced
    ))
    
    // Create gradient by sampling at regular intervals
    var gradient = [ColorJourneyRGB]()
    for i in 0..<256 {
        let t = Float(i) / 255.0
        gradient.append(journey.sample(at: t))
    }
    
    assert(gradient.count == 256, "Gradient failed")
    print("✓ Snippet 4: Smooth gradient example compiles")
}

// MARK: - Docstring Snippet 5: UI Palette (discrete method)
func testDocSnippet_UIPalette() {
    /* From discrete() method documentation */
    let journey = ColorJourney(config: .singleAnchor(
        ColorJourneyRGB(red: 0.3, green: 0.6, blue: 0.8),
        style: .balanced
    ))
    
    let palette = journey.discrete(count: 12)
    assert(palette.count == 12, "UI palette failed")
    print("✓ Snippet 5: UI palette example compiles")
}

// MARK: - Docstring Snippet 6: Determinism Check (determinism example)
func testDocSnippet_DeterminismCheck() {
    /* From documentation about variation seeding */
    let config = ColorJourneyConfig(
        anchors: [ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)],
        variation: .subtle(dimensions: [.hue], seed: 12345)
    )
    
    let journey1 = ColorJourney(config: config)
    let palette1 = journey1.discrete(count: 5)
    
    let journey2 = ColorJourney(config: config)
    let palette2 = journey2.discrete(count: 5)
    
    assert(palette1 == palette2, "Determinism failed")
    print("✓ Snippet 6: Determinism check compiles and passes")
}

// MARK: - Docstring Snippet 7: Style Presets
func testDocSnippet_StylePresets() {
    /* From style preset documentation */
    let baseColor = ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.8)
    
    let styles: [(String, JourneyStyle)] = [
        ("Balanced", .balanced),
        ("Pastel Drift", .pastelDrift),
        ("Vivid Loop", .vividLoop),
        ("Night Mode", .nightMode),
        ("Warm Earth", .warmEarth),
        ("Cool Sky", .coolSky)
    ]
    
    for (_, style) in styles {
        let journey = ColorJourney(config: .singleAnchor(baseColor, style: style))
        let colors = journey.discrete(count: 3)
        assert(colors.count == 3, "Style preset failed")
    }
    
    print("✓ Snippet 7: Style presets example compiles")
}

// MARK: - Docstring Snippet 8: Error Handling (nil handling)
func testDocSnippet_ErrorHandling() {
    /* From error handling documentation */
    let config = ColorJourneyConfig(
        anchors: [ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)]
    )
    let journey = ColorJourney(config: config)
    
    // Sample with valid parameter
    let color = journey.sample(at: 0.5)
    assert(color.red >= 0.0, "Error handling failed")
    print("✓ Snippet 8: Error handling example compiles")
}

// MARK: - Docstring Snippet 9: Multi-anchor Journey
func testDocSnippet_MultiAnchorJourney() {
    /* From multi-anchor example documentation */
    let journey = ColorJourney(config: ColorJourneyConfig(
        anchors: [
            ColorJourneyRGB(red: 1.0, green: 0.2, blue: 0.2),
            ColorJourneyRGB(red: 0.2, green: 1.0, blue: 0.2),
            ColorJourneyRGB(red: 0.2, green: 0.2, blue: 1.0)
        ],
        loopMode: .closed
    ))
    
    let palette = journey.discrete(count: 6)
    assert(palette.count == 6, "Multi-anchor failed")
    print("✓ Snippet 9: Multi-anchor journey compiles")
}

// MARK: - Test Runner

func runAllDocstringValidations() {
    print("╔════════════════════════════════════════════╗")
    print("║  Docstring Code Snippet Validation         ║")
    print("╚════════════════════════════════════════════╝\n")
    
    testDocSnippet_BasicSingleAnchorConfig()
    testDocSnippet_AdvancedConfig()
    testDocSnippet_ConstructorExample()
    testDocSnippet_SmoothGradient()
    testDocSnippet_UIPalette()
    testDocSnippet_DeterminismCheck()
    testDocSnippet_StylePresets()
    testDocSnippet_ErrorHandling()
    testDocSnippet_MultiAnchorJourney()
    
    print("\n✅ All 9 docstring code snippets validated successfully!")
}

// Uncomment to run:
// runAllDocstringValidations()
