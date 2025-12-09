import UIKit
import ColorJourney

/// ColorJourney CocoaPods Demo - Usage Sample
/// 
/// This sample demonstrates how to use ColorJourney after installing via CocoaPods.
/// 
/// Installation:
///   1. Add to Podfile: pod 'ColorJourney'
///   2. Run: pod install
///   3. Open .xcworkspace file in Xcode

// MARK: - Single Anchor Palette

func generateSingleAnchorPalette() {
    // Create a base color (Linear sRGB)
    let baseColor = ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)
    
    // Create a journey with a single anchor color
    let journey = ColorJourney(
        config: .singleAnchor(baseColor, style: .balanced)
    )
    
    // Generate 8 discrete colors for a UI palette
    let colors = journey.discrete(count: 8)
    
    print("Single Anchor Palette (8 colors):")
    for (index, color) in colors.enumerated() {
        print("  [\(index)] R:\(String(format: "%.2f", color.red)) G:\(String(format: "%.2f", color.green)) B:\(String(format: "%.2f", color.blue))")
    }
}

// MARK: - Continuous Sampling

func sampleContinuousPalette() {
    let baseColor = ColorJourneyRGB(red: 0.2, green: 0.6, blue: 0.3)
    
    let journey = ColorJourney(
        config: .singleAnchor(baseColor, style: .vibrant)
    )
    
    // Sample at arbitrary points for gradient generation
    let samples = (0...20).map { i -> ColorJourneyRGB in
        let t = Float(i) / 20.0
        return journey.sample(at: t)
    }
    
    print("Continuous Gradient (21 samples from t=0 to t=1):")
    for (index, color) in samples.enumerated() {
        let t = Float(index) / 20.0
        print(String(format: "  [t=%.2f] RGB(%.2f, %.2f, %.2f)", t, color.red, color.green, color.blue))
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

@available(iOS 14, macOS 11, *)
struct ColorJourneyDemoView: View {
    let journey: ColorJourney
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ColorJourney Gradient")
                .font(.headline)
            
            // Display gradient using SwiftUI
            Rectangle()
                .fill(journey.linearGradient(stops: 20))
                .frame(height: 100)
                .cornerRadius(10)
            
            // Display discrete palette as swatches
            HStack(spacing: 10) {
                ForEach(journey.discrete(count: 5).indices, id: \.self) { index in
                    let color = journey.discrete(count: 5)[index]
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: Double(color.red), green: Double(color.green), blue: Double(color.blue)))
                        .frame(height: 50)
                }
            }
            .padding()
        }
        .padding()
    }
}

// MARK: - Demo Styles

func demonstrateStyles() {
    let baseColor = ColorJourneyRGB(red: 0.4, green: 0.4, blue: 0.6)
    
    let styles: [(String, JourneyStyle)] = [
        ("Balanced", .balanced),
        ("Vibrant", .vibrant),
        ("Muted", .muted),
        ("Pastel", .pastel),
        ("Dark", .dark),
        ("High Contrast", .highContrast)
    ]
    
    for (styleName, style) in styles {
        let journey = ColorJourney(
            config: .singleAnchor(baseColor, style: style)
        )
        
        let firstColor = journey.sample(at: 0.0)
        let midColor = journey.sample(at: 0.5)
        let lastColor = journey.sample(at: 1.0)
        
        print("\(styleName) Style:")
        print("  Start: RGB(\(String(format: "%.2f", firstColor.red)), \(String(format: "%.2f", firstColor.green)), \(String(format: "%.2f", firstColor.blue)))")
        print("  Mid:   RGB(\(String(format: "%.2f", midColor.red)), \(String(format: "%.2f", midColor.green)), \(String(format: "%.2f", midColor.blue)))")
        print("  End:   RGB(\(String(format: "%.2f", lastColor.red)), \(String(format: "%.2f", lastColor.green)), \(String(format: "%.2f", lastColor.blue)))")
    }
}

// MARK: - Main Demo Entry Point

func runColorJourneyDemo() {
    print("=== ColorJourney CocoaPods Demo ===\n")
    
    print("1. Single Anchor Palette")
    print("-" * 40)
    generateSingleAnchorPalette()
    print()
    
    print("2. Continuous Sampling")
    print("-" * 40)
    sampleContinuousPalette()
    print()
    
    print("3. Journey Styles")
    print("-" * 40)
    demonstrateStyles()
    print()
    
    print("=== Demo Complete ===")
    print("Check the console output above to see color values.")
    print("For SwiftUI integration, see ColorJourneyDemoView.")
}
