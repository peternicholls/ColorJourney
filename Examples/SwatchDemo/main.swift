#!/usr/bin/env swift

/**
 * Incremental Swatch Demo - ColorJourney CLI Tool
 *
 * A practical demonstration of the palette engine's incremental access patterns.
 * Shows how applications can dynamically access colors without knowing upfront how many they'll need.
 *
 * This demo requires the ColorJourney package to be compiled.
 *
 * Recommended usage:
 *   Add as an executable target in Package.swift, then:
 *   swift build -c release && .build/release/swatch-demo
 *
 * For Package.swift:
 *   - Add this file to Sources/SwatchDemo/main.swift
 *   - Add to products: .executable(name: "swatch-demo", targets: ["SwatchDemo"])
 *   - Add dependency: .target(name: "SwatchDemo", dependencies: ["ColorJourney"])
 */

import Foundation
import ColorJourney

// MARK: - ANSI Color Support

struct ANSIColor {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    
    var escapeCode: String {
        "38;2;\(r);\(g);\(b)"
    }
    
    func swatch(width: Int = 4) -> String {
        "\u{001B}[\(escapeCode)m" + String(repeating: "█", count: width) + "\u{001B}[0m"
    }
}

// MARK: - Helper Functions

func separator(_ length: Int = 80) -> String {
    String(repeating: "=", count: length)
}

func dash(_ length: Int = 40) -> String {
    String(repeating: "-", count: length)
}

func displayColorRow(_ colors: [ColorJourneyRGB]) {
    var row = "   "
    for color in colors {
        let ansi = ANSIColor(
            r: UInt8(color.red * 255),
            g: UInt8(color.green * 255),
            b: UInt8(color.blue * 255)
        )
        row += ansi.swatch() + " "
    }
    print(row)
}

func colorsEqual(_ a: [ColorJourneyRGB], _ b: [ColorJourneyRGB]) -> Bool {
    guard a.count == b.count else { return false }
    for (c1, c2) in zip(a, b) {
        if abs(c1.red - c2.red) > 1e-5 ||
           abs(c1.green - c2.green) > 1e-5 ||
           abs(c1.blue - c2.blue) > 1e-5 {
            return false
        }
    }
    return true
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Demo 1: Progressive UI Building

func demo1_ProgressiveUIBuilding() {
    print("\n\(separator())")
    print("DEMO 1: Progressive UI Building")
    print("Simulating: User adds timeline tracks one at a time")
    print(separator())
    
    let baseColor = ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8)
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    
    print("\nUser Action → Color Assigned")
    print(dash())
    
    let trackNames = ["Background", "Foreground", "Lighting", "FX", "Audio"]
    
    for (index, trackName) in trackNames.enumerated() {
        let color = journey[index]
        let ansi = ANSIColor(
            r: UInt8(color.red * 255),
            g: UInt8(color.green * 255),
            b: UInt8(color.blue * 255)
        )
        
        print("User creates track '\(trackName)'")
        print("  → Index: \(index)")
        print("     \(ansi.swatch())  RGB(\(String(format: "%.2f", color.red)), \(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))")
        print()
    }
    
    print("💡 Pattern: Each track gets its color on-demand using subscript access")
    print("   journey[0], journey[1], journey[2], etc.")
}

// MARK: - Demo 2: Tag System

func demo2_TagSystem() {
    print("\n\(separator())")
    print("DEMO 2: Tag System (Tag Cloud)")
    print("Simulating: Document starts with 3 tags, user adds 2 more")
    print(separator())
    
    let baseColor = ColorJourneyRGB(red: 0.6, green: 0.3, blue: 0.7)
    let config = ColorJourneyConfig(
        anchors: [baseColor],
        contrast: .high
    )
    let journey = ColorJourney(config: config)
    
    print("\nInitial Tags (3):")
    print(dash())
    let initialTags = ["swift", "ios", "design"]
    let initialColors = journey.discrete(range: 0..<3)
    
    for (tag, color) in zip(initialTags, initialColors) {
        let ansi = ANSIColor(
            r: UInt8(color.red * 255),
            g: UInt8(color.green * 255),
            b: UInt8(color.blue * 255)
        )
        print("\(ansi.swatch(width: 2))  #\(tag)")
    }
    
    print("\nUser adds 2 more tags:")
    print(dash())
    let newTags = ["performance", "animation"]
    
    for (offset, tag) in newTags.enumerated() {
        let index = 3 + offset
        let color = journey[index]
        let ansi = ANSIColor(
            r: UInt8(color.red * 255),
            g: UInt8(color.green * 255),
            b: UInt8(color.blue * 255)
        )
        print("  → Adding '\(tag)' at index \(index)")
        print("     \(ansi.swatch())  RGB(\(String(format: "%.2f", color.red)), \(String(format: "%.2f", color.green)), \(String(format: "%.2f", color.blue)))")
    }
    
    print("\n💡 Pattern: Mix of range access (batch) + index access (incremental)")
    print("   Initial: journey.discrete(range: 0..<3)")
    print("   Later:   journey[3], journey[4]")
}

// MARK: - Demo 3: Responsive Layout

func demo3_ResponsiveLayout() {
    print("\n\(separator())")
    print("DEMO 3: Responsive Layout")
    print("Simulating: Screen resizes, number of visible columns changes")
    print(separator())
    
    let baseColor = ColorJourneyRGB(red: 0.2, green: 0.6, blue: 0.4)
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: .vividLoop))
    
    let scenarios = [
        ("Mobile (1 column)", 1),
        ("Tablet (2 columns)", 2),
        ("Desktop (4 columns)", 4),
        ("Ultra-wide (6 columns)", 6)
    ]
    
    for (scenario, columnCount) in scenarios {
        print("\n\(scenario):")
        print(dash())
        
        let colors = Array(journey.discreteColors.prefix(columnCount))
        var line = ""
        for color in colors {
            let ansi = ANSIColor(
                r: UInt8(color.red * 255),
                g: UInt8(color.green * 255),
                b: UInt8(color.blue * 255)
            )
            line += ansi.swatch(width: 6) + " "
        }
        print(line)
        
        print("Colors: \(columnCount)")
        print("Access: journey.discreteColors.prefix(\(columnCount))")
    }
    
    print("\n💡 Pattern: Lazy sequence adapts to dynamic column count")
    print("   Works with any size: prefix(1), prefix(4), prefix(100), etc.")
}

// MARK: - Demo 4: Data Visualization

func demo4_DataVisualization() {
    print("\n\(separator())")
    print("DEMO 4: Data Visualization")
    print("Simulating: Chart needs colors for N categories (N varies)")
    print(separator())
    
    let anchors = [
        ColorJourneyRGB(red: 1.0, green: 0.3, blue: 0.3),
        ColorJourneyRGB(red: 0.3, green: 1.0, blue: 0.3)
    ]
    let config = ColorJourneyConfig(
        anchors: anchors,
        contrast: .high,
        loopMode: .closed
    )
    let journey = ColorJourney(config: config)
    
    let datasets = [
        ("Quarterly Results", 4),
        ("Monthly Breakdown", 12),
        ("Weekly Trends", 26)
    ]
    
    for (chartName, categoryCount) in datasets {
        print("\n\(chartName) (\(categoryCount) categories):")
        print(dash())
        
        let colors = journey.discrete(range: 0..<categoryCount)
        
        for chunk in colors.chunked(into: 10) {
            var row = ""
            for color in chunk {
                let ansi = ANSIColor(
                    r: UInt8(color.red * 255),
                    g: UInt8(color.green * 255),
                    b: UInt8(color.blue * 255)
                )
                row += ansi.swatch() + " "
            }
            print(row)
        }
        
        print("Accessed: journey.discrete(range: 0..<\(categoryCount))")
    }
    
    print("\n💡 Pattern: Batch access via range for known count")
    print("   Efficient for pre-computing entire palette")
}

// MARK: - Demo 5: Access Pattern Comparison

func demo5_AccessPatternComparison() {
    print("\n\(separator())")
    print("DEMO 5: Access Pattern Comparison")
    print("All patterns produce identical colors")
    print(separator())
    
    let baseColor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
    let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    
    print("\nGenerating 5 colors via 4 different patterns:\n")
    
    print("1️⃣  Subscript Access")
    print("   Colors: journey[0], journey[1], journey[2], ...")
    print("   \(dash(30))")
    var subscriptColors: [ColorJourneyRGB] = []
    for i in 0..<5 {
        subscriptColors.append(journey[i])
    }
    displayColorRow(subscriptColors)
    
    print("\n2️⃣  Index Method")
    print("   Colors: journey.discrete(at: 0), .discrete(at: 1), ...")
    print("   \(dash(30))")
    var atColors: [ColorJourneyRGB] = []
    for i in 0..<5 {
        atColors.append(journey.discrete(at: i))
    }
    displayColorRow(atColors)
    
    print("\n3️⃣  Range Method")
    print("   Colors: journey.discrete(range: 0..<5)")
    print("   \(dash(30))")
    let rangeColors = journey.discrete(range: 0..<5)
    displayColorRow(rangeColors)
    
    print("\n4️⃣  Lazy Sequence")
    print("   Colors: journey.discreteColors.prefix(5)")
    print("   \(dash(30))")
    let lazyColors = Array(journey.discreteColors.prefix(5))
    displayColorRow(lazyColors)
    
    print("\n✅ Verification:")
    print(dash())
    
    let allPatterns = [
        ("Subscript", subscriptColors),
        ("Index Method", atColors),
        ("Range Method", rangeColors),
        ("Lazy Sequence", lazyColors)
    ]
    
    var allMatch = true
    for (name, colors) in allPatterns {
        let match = colorsEqual(colors, rangeColors)
        print("\(match ? "✓" : "✗") \(name): \(match ? "IDENTICAL" : "DIFFERS")")
        allMatch = allMatch && match
    }
    
    print("\n💡 All 4 patterns produce identical results!")
    print("   Choose based on your use case:")
    print("   • Subscript [i]: Simplest, most intuitive")
    print("   • discrete(at:): Explicit, clear intent")
    print("   • discrete(range:): Best for batches, efficient")
    print("   • discreteColors: Best for streaming/lazy evaluation")
}

// MARK: - Demo 6: Style Showcase

func demo6_StyleShowcase() {
    print("\n\(separator())")
    print("DEMO 6: Style Showcase")
    print("Different journey styles for different aesthetic goals")
    print(separator())
    
    let styles: [(String, JourneyStyle)] = [
        ("Balanced", .balanced),
        ("Pastel Drift", .pastelDrift),
        ("Vivid Loop", .vividLoop),
        ("Night Mode", .nightMode),
        ("Warm Earth", .warmEarth),
        ("Cool Sky", .coolSky)
    ]
    
    let baseColor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
    
    for (styleName, style) in styles {
        print("\n\(styleName):")
        print(dash())
        
        let journey = ColorJourney(config: .singleAnchor(baseColor, style: style))
        let colors = journey.discrete(count: 6)
        
        var row = ""
        for color in colors {
            let ansi = ANSIColor(
                r: UInt8(color.red * 255),
                g: UInt8(color.green * 255),
                b: UInt8(color.blue * 255)
            )
            row += ansi.swatch() + " "
        }
        print(row)
    }
    
    print("\n💡 6 pre-configured styles for different moods and applications")
}

// MARK: - Main

func main() {
    print("\n")
    print("╔" + String(repeating: "═", count: 78) + "╗")
    print("║" + "Incremental Swatch Demo - ColorJourney Palette Engine".padding(toLength: 78, withPad: " ", startingAt: 0) + "║")
    print("╚" + String(repeating: "═", count: 78) + "╝")
    
    demo1_ProgressiveUIBuilding()
    demo2_TagSystem()
    demo3_ResponsiveLayout()
    demo4_DataVisualization()
    demo5_AccessPatternComparison()
    demo6_StyleShowcase()
    
    print("\n\(separator())")
    print("SUMMARY")
    print(separator())
    
    print("""
    
    The Palette Engine supports multiple access patterns for different scenarios:
    
    ✓ SINGLE INDEX (journey[i], journey.discrete(at: i))
      Use when: Adding elements one at a time
      Example: Timeline tracks, tags, progressive UI building
    
    ✓ RANGE ACCESS (journey.discrete(range: start..<end))
      Use when: Need a batch of sequential colors
      Example: Charts with N categories, column grids
    
    ✓ LAZY SEQUENCE (journey.discreteColors.prefix(n))
      Use when: Dynamic count, streaming, responsive layouts
      Example: Adapting to screen size, progressive loading
    
    ✓ BATCH (journey.discrete(count: n))
      Use when: Count known upfront
      Example: Pre-generating entire palettes
    
    All patterns produce identical, deterministic colors.
    Choose based on your access pattern for best readability.
    
    🎨 The palette engine is portable (C99 core + Swift wrapper),
       deterministic, and optimized for real-time color generation.
    
    """)
    
    print(separator())
    print("Demo complete! ✨\n")
}

main()
