/*:
 # ColorJourney Feature Playground
 
 An interactive exploration of all ColorJourney features.
 
 This Playground demonstrates every public API in the ColorJourney library,
 building on the proven SwatchDemo CLI tool with visual, interactive examples.
 
 ## Navigation
 
 Use the page navigator to explore:
 
 1. **Introduction** - You are here! Overview and setup
 2. **Color Basics** - RGB colors, conversions, platform support
 3. **Journey Styles** - All 6 pre-configured styles with visual comparison
 4. **Access Patterns** - Subscript, discrete(), lazy sequences, determinism
 5. **Configuration** - Anchors, contrast, biases, loop modes
 6. **Advanced Use Cases** - Real-world examples and patterns
 
 ## Setup
 
 This Playground requires the ColorJourney package to be built.
 
 ### Using with Xcode
 
 1. Open the ColorJourney package in Xcode
 2. Build the package (⌘B)
 3. Open this Playground file
 4. Ensure the ColorJourney scheme is selected
 
 ### Note on Visual Output
 
 This Playground uses console output with ANSI color codes for visual swatches.
 For best results, view the console output in Xcode's Debug Area.
 
 ## About ColorJourney
 
 ColorJourney generates perceptually uniform color palettes using OKLab color space.
 Perfect for UI design, data visualization, and generative art.
 
 **Key Features:**
 - Perceptually uniform color spacing
 - Incremental access patterns (don't need to know palette size upfront)
 - Multiple journey styles (balanced, pastel, vivid, night mode, etc.)
 - High-performance C core with Swift wrapper
 - Cross-platform support (iOS, macOS, watchOS, tvOS, visionOS)
 
 ---
 
 **Ready?** Navigate to **01-ColorBasics** to begin! →
 */

import Foundation
import ColorJourney

// Verify ColorJourney is imported correctly
let testColor = ColorJourneyRGB(red: 0.5, green: 0.3, blue: 0.8)
print("✅ ColorJourney loaded successfully!")
print("   Test color: RGB(\(testColor.red), \(testColor.green), \(testColor.blue))")
print("\n📘 Navigate to the next page to start exploring features.")
