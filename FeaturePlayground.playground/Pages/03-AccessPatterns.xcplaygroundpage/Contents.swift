/*:
 [Previous: Journey Styles](@previous) | [Next: Configuration](@next)
 
 # Access Patterns
 
 Explore ColorJourney's incremental access patterns.
 
 One of ColorJourney's key features is the ability to access colors incrementally
 without knowing upfront how many you'll need. This is perfect for dynamic UIs,
 progressive rendering, and responsive layouts.
 */

import Foundation
import ColorJourney

print(separator())
print("ACCESS PATTERNS - Incremental Color Generation")
print(separator())

let baseColor = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))

//: ## 1. Subscript Access (Most Common)
//: Access colors by index, just like an array

print("\n📌 1. Subscript Access")
print(dash())
print("Usage: journey[0], journey[1], journey[2], ...\n")

print("First 5 colors:")
for i in 0..<5 {
    let color = journey[i]
    displayColor(color, label: "journey[\(i)]")
}

//: ## 2. discrete(at:) Method
//: Explicit method for single color access

print("\n📌 2. discrete(at:) Method")
print(dash())
print("Usage: journey.discrete(at: index)\n")

print("Same 5 colors using discrete(at:):")
for i in 0..<5 {
    let color = journey.discrete(at: i)
    displayColor(color, label: "discrete(at: \(i))")
}

//: ## 3. discrete(count:) Method
//: Generate N colors at once (batch)

print("\n📌 3. discrete(count:) Method")
print(dash())
print("Usage: journey.discrete(count: N)\n")

let palette8 = journey.discrete(count: 8)
print("8-color palette:")
displayColorRow(palette8)

//: ## 4. discrete(range:) Method
//: Generate colors in a specific range

print("\n📌 4. discrete(range:) Method")
print(dash())
print("Usage: journey.discrete(range: start..<end)\n")

let midRange = journey.discrete(range: 3..<8)
print("Colors 3-7 (indices 3..<8):")
displayColorRow(midRange)

//: ## 5. Lazy Sequence (discreteColors)
//: Stream colors on-demand, perfect for unknown quantities

print("\n📌 5. Lazy Sequence (discreteColors)")
print(dash())
print("Usage: journey.discreteColors.prefix(N)\n")

let first6 = Array(journey.discreteColors.prefix(6))
print("First 6 colors via lazy sequence:")
displayColorRow(first6)

//: ## Determinism Verification
//: All patterns produce IDENTICAL results

print("\n" + separator())
print("DETERMINISM VERIFICATION")
print(separator())

print("\nGenerating the same 5 colors via 4 different patterns:\n")

let subscriptColors = (0..<5).map { journey[$0] }
let atColors = (0..<5).map { journey.discrete(at: $0) }
let rangeColors = journey.discrete(range: 0..<5)
let lazyColors = Array(journey.discreteColors.prefix(5))

print("1. Subscript:      ", terminator: "")
displayColorRow(subscriptColors)

print("2. discrete(at:):  ", terminator: "")
displayColorRow(atColors)

print("3. discrete(range):", terminator: "")
displayColorRow(rangeColors)

print("4. Lazy sequence:  ", terminator: "")
displayColorRow(lazyColors)

print("\n✅ Verification Results:")
print(dash())
print("Subscript == discrete(at:):    \(colorsEqual(subscriptColors, atColors) ? "✓ IDENTICAL" : "✗ DIFFERS")")
print("Subscript == discrete(range:): \(colorsEqual(subscriptColors, rangeColors) ? "✓ IDENTICAL" : "✗ DIFFERS")")
print("Subscript == lazy sequence:    \(colorsEqual(subscriptColors, lazyColors) ? "✓ IDENTICAL" : "✗ DIFFERS")")

//: ## Real-World Use Cases

print("\n" + separator())
print("REAL-WORLD USE CASES")
print(separator())

//: ### Use Case 1: Progressive UI Building
print("\n🎯 Progressive UI Building (unknown final count)")
print(dash())

let tracks = ["Background", "Foreground", "Lighting", "FX"]
for (index, track) in tracks.enumerated() {
    let color = journey[index]
    print("\(track.padding(toLength: 12, withPad: " ", startingAt: 0))", terminator: "")
    displayColor(color)
}

//: ### Use Case 2: Responsive Layout
print("\n🎯 Responsive Layout (column count changes)")
print(dash())

let layouts = [
    ("Mobile", 2),
    ("Tablet", 4),
    ("Desktop", 6)
]

for (device, columns) in layouts {
    let colors = Array(journey.discreteColors.prefix(columns))
    print("\(device) (\(columns) cols): ", terminator: "")
    for color in colors {
        let ansi = ANSIColor(from: color)
        print(ansi.swatch(width: 3), terminator: " ")
    }
    print()
}

//: ### Use Case 3: Tag System (mixed access)
print("\n🎯 Tag System (batch + incremental)")
print(dash())

// Initial tags (batch)
let initialTags = journey.discrete(count: 3)
print("Initial 3 tags: ", terminator: "")
displayColorRow(initialTags)

// User adds 2 more (incremental)
print("Add tag 4:      ", terminator: "")
displayColor(journey[3])
print("Add tag 5:      ", terminator: "")
displayColor(journey[4])

print("\n💡 Key Points:")
print("   • All access patterns produce IDENTICAL colors")
print("   • Choose pattern based on your use case:")
print("     - journey[i]: Simplest, most intuitive")
print("     - discrete(at:): Explicit, clear intent")
print("     - discrete(count:): Best for known batch sizes")
print("     - discrete(range:): Best for specific ranges")
print("     - discreteColors: Best for streaming/unknown quantities")
print("   • Deterministic: Same config = same colors, every time")
print("   • No upfront commitment to palette size")

print("\n" + separator())

/*:
 ---
 
 ## Summary
 
 You've learned:
 - 5 different ways to access colors from a journey
 - All patterns produce identical, deterministic results
 - Real-world use cases for incremental access
 - How to choose the right pattern for your needs
 
 **Key Insight:** You never need to know upfront how many colors you'll need.
 Generate them on-demand as your application requires.
 
 **Next:** Learn about configuration options and customization →
 
 [Previous: Journey Styles](@previous) | [Next: Configuration](@next)
 */
