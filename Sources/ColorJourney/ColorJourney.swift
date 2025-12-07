/*
 * ColorJourney System - Swift Interface
 * High-level Swift API wrapping high-performance C core
 */

import Foundation
import CColorJourney

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Swift Types

public struct ColorJourneyRGB: Hashable {
    public var red: Float
    public var green: Float
    public var blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    #if canImport(SwiftUI)
    public var color: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
    #endif

    #if canImport(AppKit)
    public var nsColor: NSColor {
        NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
    #endif

    #if canImport(UIKit)
    public var uiColor: UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
    #endif
}

// MARK: - Configuration Enums

public enum LightnessBias {
    case neutral
    case lighter
    case darker
    case custom(weight: Float) // [-1, 1]
}

public enum ChromaBias {
    case neutral
    case muted
    case vivid
    case custom(multiplier: Float) // [0.5, 2.0]
}

public enum ContrastLevel {
    case low
    case medium
    case high
    case custom(threshold: Float) // Minimum OKLab ΔE
}

public enum TemperatureBias {
    case neutral
    case warm
    case cool
}

public enum LoopMode {
    case open
    case closed
    case pingPong
}

public struct VariationConfig {
    public var enabled: Bool
    public var dimensions: VariationDimensions
    public var strength: VariationStrength
    public var seed: UInt64

    public init(
        enabled: Bool = false,
        dimensions: VariationDimensions = [],
        strength: VariationStrength = .subtle,
        seed: UInt64 = 0x123456789ABCDEF0
    ) {
        self.enabled = enabled
        self.dimensions = dimensions
        self.strength = strength
        self.seed = seed
    }

    public static var off: VariationConfig {
        VariationConfig(enabled: false)
    }

    public static func subtle(dimensions: VariationDimensions, seed: UInt64? = nil) -> VariationConfig {
        VariationConfig(
            enabled: true,
            dimensions: dimensions,
            strength: .subtle,
            seed: seed ?? 0x123456789ABCDEF0
        )
    }
}

public struct VariationDimensions: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let hue = VariationDimensions(rawValue: 1 << 0)
    public static let lightness = VariationDimensions(rawValue: 1 << 1)
    public static let chroma = VariationDimensions(rawValue: 1 << 2)

    public static let all: VariationDimensions = [.hue, .lightness, .chroma]
}

public enum VariationStrength {
    case subtle
    case noticeable
    case custom(magnitude: Float)
}

// MARK: - Journey Configuration

public struct ColorJourneyConfig {
    public var anchors: [ColorJourneyRGB]
    public var lightness: LightnessBias
    public var chroma: ChromaBias
    public var contrast: ContrastLevel
    public var midJourneyVibrancy: Float // [0, 1]
    public var temperature: TemperatureBias
    public var loopMode: LoopMode
    public var variation: VariationConfig

    public init(
        anchors: [ColorJourneyRGB],
        lightness: LightnessBias = .neutral,
        chroma: ChromaBias = .neutral,
        contrast: ContrastLevel = .medium,
        midJourneyVibrancy: Float = 0.3,
        temperature: TemperatureBias = .neutral,
        loopMode: LoopMode = .open,
        variation: VariationConfig = .off
    ) {
        self.anchors = anchors
        self.lightness = lightness
        self.chroma = chroma
        self.contrast = contrast
        self.midJourneyVibrancy = midJourneyVibrancy
        self.temperature = temperature
        self.loopMode = loopMode
        self.variation = variation
    }

    // MARK: Preset Builders

    public static func singleAnchor(
        _ color: ColorJourneyRGB,
        style: JourneyStyle = .balanced
    ) -> ColorJourneyConfig {
        style.apply(to: ColorJourneyConfig(anchors: [color]))
    }

    public static func multiAnchor(
        _ colors: [ColorJourneyRGB],
        style: JourneyStyle = .balanced
    ) -> ColorJourneyConfig {
        style.apply(to: ColorJourneyConfig(anchors: colors))
    }
}

// MARK: - Journey Styles (Presets)

public enum JourneyStyle {
    case balanced
    case pastelDrift
    case vividLoop
    case nightMode
    case warmEarth
    case coolSky
    case custom(
        lightness: LightnessBias,
        chroma: ChromaBias,
        contrast: ContrastLevel,
        temperature: TemperatureBias
    )

    func apply(to config: ColorJourneyConfig) -> ColorJourneyConfig {
        var result = config

        switch self {
        case .balanced:
            result.lightness = .neutral
            result.chroma = .neutral
            result.contrast = .medium
            result.temperature = .neutral

        case .pastelDrift:
            result.lightness = .lighter
            result.chroma = .muted
            result.contrast = .low
            result.midJourneyVibrancy = 0.1

        case .vividLoop:
            result.lightness = .neutral
            result.chroma = .vivid
            result.contrast = .high
            result.loopMode = .closed
            result.midJourneyVibrancy = 0.5

        case .nightMode:
            result.lightness = .darker
            result.chroma = .custom(multiplier: 0.8)
            result.contrast = .medium

        case .warmEarth:
            result.temperature = .warm
            result.chroma = .custom(multiplier: 0.9)
            result.lightness = .custom(weight: -0.1)

        case .coolSky:
            result.temperature = .cool
            result.lightness = .lighter
            result.chroma = .neutral

        case .custom(let l, let c, let con, let t):
            result.lightness = l
            result.chroma = c
            result.contrast = con
            result.temperature = t
        }

        return result
    }
}

// MARK: - Journey

public final class ColorJourney {
    private var handle: OpaquePointer?

    public init(config: ColorJourneyConfig) {
        var cConfig = CJ_Config()
        cj_config_init(&cConfig)

        Self.configureAnchors(&cConfig, from: config)
        Self.configureLightness(&cConfig, from: config)
        Self.configureChroma(&cConfig, from: config)
        Self.configureContrast(&cConfig, from: config)
        cConfig.mid_journey_vibrancy = config.midJourneyVibrancy
        Self.configureTemperature(&cConfig, from: config)
        Self.configureLoopMode(&cConfig, from: config)
        Self.configureVariation(&cConfig, from: config)

        handle = cj_journey_create(&cConfig)
    }

    private static func configureAnchors(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        cConfig.anchor_count = Int32(min(config.anchors.count, 8))
        var anchors = [CJ_RGB](repeating: CJ_RGB(r: 0, g: 0, b: 0), count: 8)
        for (index, anchor) in config.anchors.prefix(8).enumerated() {
            anchors[index] = CJ_RGB(r: anchor.red, g: anchor.green, b: anchor.blue)
        }
        cConfig.anchors = (
            anchors[0], anchors[1], anchors[2], anchors[3],
            anchors[4], anchors[5], anchors[6], anchors[7]
        )
    }

    private static func configureLightness(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.lightness {
        case .neutral:
            cConfig.lightness_bias = CJ_LIGHTNESS_NEUTRAL
        case .lighter:
            cConfig.lightness_bias = CJ_LIGHTNESS_LIGHTER
        case .darker:
            cConfig.lightness_bias = CJ_LIGHTNESS_DARKER
        case .custom(let weight):
            cConfig.lightness_bias = CJ_LIGHTNESS_CUSTOM
            cConfig.lightness_custom_weight = weight
        }
    }

    private static func configureChroma(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.chroma {
        case .neutral:
            cConfig.chroma_bias = CJ_CHROMA_NEUTRAL
        case .muted:
            cConfig.chroma_bias = CJ_CHROMA_MUTED
        case .vivid:
            cConfig.chroma_bias = CJ_CHROMA_VIVID
        case .custom(let mult):
            cConfig.chroma_bias = CJ_CHROMA_CUSTOM
            cConfig.chroma_custom_multiplier = mult
        }
    }

    private static func configureContrast(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.contrast {
        case .low:
            cConfig.contrast_level = CJ_CONTRAST_LOW
        case .medium:
            cConfig.contrast_level = CJ_CONTRAST_MEDIUM
        case .high:
            cConfig.contrast_level = CJ_CONTRAST_HIGH
        case .custom(let threshold):
            cConfig.contrast_level = CJ_CONTRAST_CUSTOM
            cConfig.contrast_custom_threshold = threshold
        }
    }

    private static func configureTemperature(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.temperature {
        case .neutral:
            cConfig.temperature_bias = CJ_TEMPERATURE_NEUTRAL
        case .warm:
            cConfig.temperature_bias = CJ_TEMPERATURE_WARM
        case .cool:
            cConfig.temperature_bias = CJ_TEMPERATURE_COOL
        }
    }

    private static func configureLoopMode(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.loopMode {
        case .open:
            cConfig.loop_mode = CJ_LOOP_OPEN
        case .closed:
            cConfig.loop_mode = CJ_LOOP_CLOSED
        case .pingPong:
            cConfig.loop_mode = CJ_LOOP_PINGPONG
        }
    }

    private static func configureVariation(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        cConfig.variation_enabled = config.variation.enabled
        cConfig.variation_dimensions = config.variation.dimensions.rawValue
        switch config.variation.strength {
        case .subtle:
            cConfig.variation_strength = CJ_VARIATION_SUBTLE
        case .noticeable:
            cConfig.variation_strength = CJ_VARIATION_NOTICEABLE
        case .custom(let mag):
            cConfig.variation_strength = CJ_VARIATION_CUSTOM
            cConfig.variation_custom_magnitude = mag
        }
        cConfig.variation_seed = config.variation.seed
    }

    deinit {
        if let handle = handle {
            cj_journey_destroy(handle)
        }
    }

    /// Sample the journey at parameter t ∈ [0, 1]
    public func sample(at parameterT: Float) -> ColorJourneyRGB {
        guard let handle = handle else {
            return ColorJourneyRGB(red: 0, green: 0, blue: 0)
        }

        let rgb = cj_journey_sample(handle, parameterT)
        return ColorJourneyRGB(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    /// Generate N discrete, perceptually distinct colors
    public func discrete(count: Int) -> [ColorJourneyRGB] {
        guard let handle = handle, count > 0 else {
            return []
        }

        var colors = [CJ_RGB](repeating: CJ_RGB(r: 0, g: 0, b: 0), count: count)
        colors.withUnsafeMutableBufferPointer { buffer in
            cj_journey_discrete(handle, Int32(count), buffer.baseAddress!)
        }

        return colors.map { ColorJourneyRGB(red: $0.r, green: $0.g, blue: $0.b) }
    }
}

// MARK: - Convenience Extensions

#if canImport(SwiftUI)
extension ColorJourney {
    /// Create a SwiftUI gradient from the journey
    public func gradient(stops: Int = 10) -> Gradient {
        let colors = (0..<stops).map { index in
            sample(at: Float(index) / Float(stops - 1)).color
        }
        return Gradient(colors: colors)
    }

    /// Create a linear gradient
    public func linearGradient(
        stops: Int = 10,
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> LinearGradient {
        LinearGradient(
            gradient: gradient(stops: stops),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// MARK: - Color Utilities for SwiftUI

extension Color {
    public init(journeyRGB: ColorJourneyRGB) {
        self = journeyRGB.color
    }
}
#endif

// MARK: - Example Usage & Documentation

/*
 EXAMPLE USAGE:

 // Simple single-anchor journey
 let journey = ColorJourney(
     config: .singleAnchor(
         ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8),
         style: .balanced
     )
 )

 // Sample continuously
 let color = journey.sample(at: 0.5)

 // Get discrete palette
 let palette = journey.discrete(count: 10)

 // Multi-anchor with variation
 let config = ColorJourneyConfig(
     anchors: [
         ColorJourneyRGB(red: 1.0, green: 0.3, blue: 0.3),
         ColorJourneyRGB(red: 0.3, green: 1.0, blue: 0.3),
         ColorJourneyRGB(red: 0.3, green: 0.3, blue: 1.0)
     ],
     loopMode: .closed,
     variation: .subtle(dimensions: [.hue, .lightness])
 )
 let journey2 = ColorJourney(config: config)

 // SwiftUI gradient
 #if canImport(SwiftUI)
 let gradient = journey.linearGradient(stops: 20)
 #endif
 */
