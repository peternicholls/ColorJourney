/*
 * ColorJourney System - Swift Interface
 * High-level Swift API wrapping high-performance C core
 *
 * CORE PRINCIPLES (See .specify/memory/constitution.md):
 *
 * Principle I - Portability:
 *   Works across all Apple platforms (iOS 13+, macOS 10.15+, watchOS 6+, etc.)
 *   by wrapping portable C core. Minimal Apple-specific code (SwiftUI extensions).
 *
 * Principle II - Perceptual Integrity:
 *   Delegates all color math to perceptually-designed C core operating in
 *   OKLab space. Wrapper provides perceptual language (not technical):
 *   "vivid", "warm", "high contrast" — not "1.4x chroma multiplier".
 *
 * Principle III - Designer-Centric Design:
 *   Preset journey styles (balanced, pastel, vivid, warmEarth, coolSky, nightMode)
 *   ensure good results "out of the box" without color theory knowledge.
 *   Type-safe enums prevent invalid configurations.
 *
 * Principle IV - Determinism:
 *   Faithfully delegates to deterministic C core. Seeded variation is
 *   reproducible. Same config + same seed = identical palette.
 *
 * Principle V - Performance:
 *   Minimal overhead: direct C interop, no copying for sampling, efficient
 *   discrete palette generation. Inherits C core's ~0.6 μs per sample.
 */

import Foundation
import CColorJourney

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Swift Types

/// Represents a color in linear sRGB color space.
///
/// This structure holds color components as floating-point values in the range [0, 1]:
/// - `red`: Red component (0 = no red, 1 = maximum red)
/// - `green`: Green component (0 = no green, 1 = maximum green)
/// - `blue`: Blue component (0 = no blue, 1 = maximum blue)
///
/// Colors can be converted to platform-specific formats via convenience properties:
/// - `.color` → SwiftUI `Color`
/// - `.uiColor` → UIKit `UIColor` (iOS/iPadOS)
/// - `.nsColor` → AppKit `NSColor` (macOS)
///
/// ## Perceptual Interpretation
///
/// Internally, ColorJourney operates in OKLab perceptual space for all color math.
/// `ColorJourneyRGB` is the public-facing format for input/output, automatically
/// converted to/from OKLab as needed.
///
/// - SeeAlso: [OKLab Color Space](https://bottosson.github.io/posts/oklab/)
public struct ColorJourneyRGB: Hashable {
    public var red: Float
    public var green: Float
    public var blue: Float

    /// Initialize a color with linear sRGB components.
    ///
    /// - Parameters:
    ///   - red: Red component [0, 1]
    ///   - green: Green component [0, 1]
    ///   - blue: Blue component [0, 1]
    ///
    /// Values outside [0, 1] are technically valid (extended RGB gamut) but represent
    /// colors outside the sRGB color space. Most displays can't show these directly.
    public init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    #if canImport(SwiftUI)
    /// SwiftUI Color representation of this RGB value.
    ///
    /// Converts the linear sRGB components to a SwiftUI `Color` for use in
    /// views and gradients.
    public var color: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
    #endif

    #if canImport(AppKit)
    /// AppKit NSColor representation (macOS).
    ///
    /// Returns an `NSColor` in sRGB color space with alpha = 1.0 (fully opaque).
    public var nsColor: NSColor {
        NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
    #endif

    #if canImport(UIKit)
    /// UIKit UIColor representation (iOS, iPadOS).
    ///
    /// Returns a `UIColor` in sRGB color space with alpha = 1.0 (fully opaque).
    public var uiColor: UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
    #endif
}

// MARK: - Configuration Enums

/// Controls overall brightness adjustment across the journey.
///
/// Lightness bias shifts the palette toward brighter or darker tones while
/// preserving hue and saturation. Useful for adapting palettes to different
/// contexts (light UI, dark UI, etc.).
///
/// ## Cases
///
/// - `.neutral`: Preserve anchor color lightness (no adjustment)
/// - `.lighter`: Shift toward brighter colors (lighter, more visible on dark backgrounds)
/// - `.darker`: Shift toward darker colors (darker, more visible on light backgrounds)
/// - `.custom(weight:)`: Manual adjustment [-1 = darker, +1 = lighter]
///
/// ## Perceptual Effect
///
/// The lightness adjustment shifts all colors in the journey toward the specified
/// direction by approximately 20% of the available range. For example:
/// - A medium gray (L=0.5) with `.lighter` becomes slightly lighter
/// - A medium gray with `.darker` becomes slightly darker
public enum LightnessBias {
    case neutral
    case lighter
    case darker
    /// Custom lightness weight. Range: [-1.0, 1.0]
    /// - -1.0 = maximum darkening
    /// -  0.0 = neutral (no adjustment)
    /// - +1.0 = maximum lightening
    case custom(weight: Float)
}

/// Controls saturation (colorfulness) across the journey.
///
/// Chroma bias scales the saturation without changing lightness or hue.
/// Creates distinctly different emotional tones:
/// - Muted: Soft, pastel, sophisticated
/// - Vivid: Bold, saturated, energetic
///
/// ## Cases
///
/// - `.neutral`: Preserve anchor color saturation
/// - `.muted`: Reduce saturation (×0.6) for soft, pastel colors
/// - `.vivid`: Increase saturation (×1.4) for bold, vibrant colors
/// - `.custom(multiplier:)`: Manual saturation scaling [0.5, 2.0]
///
/// ## Perceptual Effect
///
/// - Muted palettes feel soft, sophisticated, and calming
/// - Vivid palettes feel energetic, bold, and attention-grabbing
/// - Custom multipliers allow fine-tuning for specific use cases
public enum ChromaBias {
    case neutral
    case muted
    case vivid
    /// Custom chroma multiplier. Range: [0.5, 2.0]
    /// - 0.5 = half saturation (muted)
    /// - 1.0 = neutral
    /// - 2.0 = double saturation (vivid)
    case custom(multiplier: Float)
}

/// Enforces minimum perceptual separation between adjacent colors.
///
/// Contrast level ensures generated colors are distinguishable from each other,
/// critical for UIs where colors must be easily read and clicked.
///
/// ## Cases
///
/// - `.low`: Soft separation (ΔE ≥ 0.05) for harmonious, subtle palettes
/// - `.medium`: Balanced separation (ΔE ≥ 0.10), recommended for most UIs
/// - `.high`: Strong distinction (ΔE ≥ 0.15) for high accessibility
/// - `.custom(threshold:)`: Custom ΔE (OKLab perceptual distance) threshold
///
/// ## Perceptual Distance (ΔE)
///
/// Perceptual distance in OKLab space:
/// - ΔE ≈ 0.05: Just noticeably different (JND)
/// - ΔE ≈ 0.10: Clearly different, readable at normal viewing
/// - ΔE ≈ 0.15: Distinct, easily distinguishable at a glance
/// - ΔE ≥ 0.20: Very different, bold contrast
///
/// ## Automatic Adjustment
///
/// If adjacent colors don't meet the threshold, their lightness and chroma
/// are automatically adjusted slightly to ensure distinction while preserving
/// the overall palette character.
public enum ContrastLevel {
    case low
    case medium
    case high
    /// Custom contrast threshold as OKLab ΔE (perceptual distance).
    /// Typical range: [0.05, 0.20]
    case custom(threshold: Float)
}

/// Shifts hue toward warm or cool regions of the color wheel.
///
/// Temperature bias rotates hue without changing lightness or saturation,
/// creating color-coordinated palettes that feel warm or cool.
///
/// ## Cases
///
/// - `.neutral`: No temperature shift (preserve hue)
/// - `.warm`: Shift toward red, orange, yellow (~+17°)
/// - `.cool`: Shift toward blue, cyan, purple (~-17°)
///
/// ## Perceptual Effect
///
/// - Warm palettes feel welcoming, energetic, and comforting
/// - Cool palettes feel calm, peaceful, and professional
/// - Temperature bias affects emotional response without changing perceived brightness
public enum TemperatureBias {
    case neutral
    case warm
    case cool
}

/// How the journey behaves at its boundaries (t=0 and t=1).
///
/// Loop mode controls what happens when sampling or wrapping around the
/// journey boundaries.
///
/// ## Cases
///
/// - `.open`: One-way journey. Color at t=0 (start) ≠ color at t=1 (end).
///   Useful for linear gradients, progressions, timelines.
/// - `.closed`: Seamless loop. Color at t=1 wraps back to t=0.
///   Useful for circular/cyclic UI elements, color wheels.
/// - `.pingPong`: Reversal. Journey goes forward (0→1) then backward (1→0).
///   Useful for animations and transitions.
///
/// ## Sampling Behavior
///
/// - Open loop: t < 0 clamps to 0; t > 1 clamps to 1
/// - Closed loop: wraps using modulo (t becomes fract(t))
/// - Ping-pong: reverses at endpoints (0→1→0 pattern)
public enum LoopMode {
    case open
    case closed
    case pingPong
}

/// Configuration for seeded variation in discrete colors.
///
/// Variation adds subtle, deterministic micro-changes to colors, creating
/// an organic, less mechanical appearance while remaining reproducible.
/// All variation is seeded—identical seeds produce identical variation patterns.
///
/// ## Structure
///
/// - `enabled`: Turn variation on/off
/// - `dimensions`: Which color axes vary (hue, lightness, chroma)
/// - `strength`: How much variation (subtle, noticeable, custom)
/// - `seed`: Deterministic seed value
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

    /// Create a subtle variation configuration with specified dimensions and optional seed.
    ///
    /// - Parameters:
    ///   - dimensions: Which color dimensions to vary
    ///   - seed: Optional custom seed. If nil, uses default deterministic seed.
    ///
    /// - Returns: VariationConfig with subtle strength and specified seed
    public static func subtle(dimensions: VariationDimensions, seed: UInt64? = nil) -> VariationConfig {
        VariationConfig(
            enabled: true,
            dimensions: dimensions,
            strength: .subtle,
            seed: seed ?? 0x123456789ABCDEF0
        )
    }
}

/// Selects which color dimensions are subject to seeded variation.
///
/// A bitfield that allows combining multiple variation dimensions:
/// - `.hue`: Vary hue angle
/// - `.lightness`: Vary brightness
/// - `.chroma`: Vary saturation
/// - `.all`: All three dimensions
///
/// Variation is deterministic (seeded), so identical configurations always
/// produce identical variation patterns.
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

/// Controls the magnitude of seeded variation.
///
/// Higher strengths produce more noticeable variation, creating a more "organic"
/// or "hand-crafted" appearance. All variation is deterministic (seeded).
///
/// ## Cases
///
/// - `.subtle`: Small variation (~1-2% per dimension), barely noticeable
/// - `.noticeable`: Medium variation (~3-5% per dimension), visible but harmonious
/// - `.custom(magnitude:)`: Custom variation strength [0.0, 1.0]
///   Note: Magnitude feeds directly into the underlying C engine—larger values
///   produce proportionally larger hue/lightness/chroma swings (e.g., 1.0 is
///   intentionally very strong). Use small values (≤0.2) for subtlety.
public enum VariationStrength {
    case subtle
    case noticeable
    /// Custom variation magnitude. Range: [0.0, 1.0]
    /// - 0.0 = no variation
    /// - 0.1–0.2 = subtle variation (~1–5% per dimension)
    /// - 0.5+ = pronounced variation (larger perceptual swings)
    case custom(magnitude: Float)
}

// MARK: - Journey Configuration

/// Complete configuration for a color journey.
///
/// `ColorJourneyConfig` specifies all parameters that shape how colors are generated:
/// the anchor color(s), perceptual biases, looping behavior, and optional variation.
///
/// ## Creating a Config
///
/// Use preset styles for quick setup:
/// ```swift
/// let config = ColorJourneyConfig.singleAnchor(
///     ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8),
///     style: .balanced
/// )
/// ```
///
/// Or customize all parameters:
/// ```swift
/// let config = ColorJourneyConfig(
///     anchors: [color1, color2],
///     lightness: .lighter,
///     chroma: .vivid,
///     contrast: .high,
///     temperature: .warm,
///     variation: .subtle(dimensions: [.hue, .lightness])
/// )
/// ```
///
/// ## Perceptual Dynamics
///
/// All configuration options control the emotional and perceptual character of the palette:
/// - **Lightness bias**: Overall brightness
/// - **Chroma bias**: Saturation (pastel vs vivid)
/// - **Contrast level**: Distinguishability of adjacent colors
/// - **Temperature bias**: Warm vs cool feeling
/// - **Mid-journey vibrancy**: Energy at the center
/// - **Variation**: Organic micro-changes (deterministic, seeded)
///
/// - SeeAlso: ``JourneyStyle`` for preset combinations
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

    /// Create a single-anchor journey with a preset style.
    ///
    /// Single-anchor journeys generate colors by rotating around the hue wheel
    /// from a base color, creating a full spectrum of variations.
    ///
    /// - Parameters:
    ///   - color: The base/anchor color in RGB
    ///   - style: Preset journey style (balanced, pastel, vivid, etc.)
    ///
    /// - Returns: Configured journey ready for use
    ///
    /// **Example:**
    /// ```swift
    /// let journey = ColorJourney(
    ///     config: .singleAnchor(
    ///         ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
    ///         style: .vividLoop
    ///     )
    /// )
    /// let palette = journey.discrete(count: 12)
    /// ```
    public static func singleAnchor(
        _ color: ColorJourneyRGB,
        style: JourneyStyle = .balanced
    ) -> ColorJourneyConfig {
        style.apply(to: ColorJourneyConfig(anchors: [color]))
    }

    /// Create a multi-anchor journey with a preset style.
    ///
    /// Multi-anchor journeys interpolate between multiple colors, creating
    /// transitions through intermediate colors. More complex and controlled
    /// than single-anchor journeys.
    ///
    /// - Parameters:
    ///   - colors: Array of 2-8 anchor colors
    ///   - style: Preset journey style (balanced, pastel, vivid, etc.)
    ///
    /// - Returns: Configured journey ready for use
    ///
    /// **Example:**
    /// ```swift
    /// let red = ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.0)
    /// let green = ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0)
    /// let blue = ColorJourneyRGB(red: 0.0, green: 0.0, blue: 1.0)
    ///
    /// let journey = ColorJourney(
    ///     config: .multiAnchor([red, green, blue], style: .balanced)
    /// )
    /// ```
    public static func multiAnchor(
        _ colors: [ColorJourneyRGB],
        style: JourneyStyle = .balanced
    ) -> ColorJourneyConfig {
        style.apply(to: ColorJourneyConfig(anchors: colors))
    }
}

// MARK: - Journey Styles (Presets)

/// Preset journey styles combining perceptual biases for common use cases.
///
/// Each style is a pre-tuned combination of lightness, chroma, contrast,
/// and temperature biases. Styles provide good results without manual tuning.
///
/// ## Available Styles
///
/// - `.balanced`: Neutral lightness, chroma, saturation. Versatile, safe default.
/// - `.pastelDrift`: Light, muted colors with soft contrast. Soft and sophisticated.
/// - `.vividLoop`: Saturated, high-contrast colors that loop seamlessly.
/// - `.nightMode`: Dark colors suitable for dark UIs and reduced eye strain.
/// - `.warmEarth`: Warm hues with natural, earthy tones.
/// - `.coolSky`: Cool hues, light and airy. Calm and professional.
/// - `.custom(...)`: Manual configuration for full control.
///
/// **Constitutional Reference**: Principle III (Designer-Centric)
/// Presets ensure good output "out of the box" without requiring color theory knowledge.
public enum JourneyStyle {
    /// Balanced: Neutral on all dimensions. Versatile, works for most cases.
    case balanced
    /// Pastel: Light, muted, soft contrast. Soft and sophisticated.
    case pastelDrift
    /// Vivid: Saturated, high-contrast, closed loop for circular color wheels.
    case vividLoop
    /// Night Mode: Dark, subdued colors for dark UIs.
    case nightMode
    /// Warm Earth: Warm-biased hues with natural, earthy character.
    case warmEarth
    /// Cool Sky: Cool-biased hues, light and airy.
    case coolSky
    /// Custom: Manually specify all four perceptual dimensions.
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

/// A color journey generator that creates palettes using perceptually uniform color math.
///
/// `ColorJourney` provides a high-level Swift API for generating color palettes based on
/// anchor colors and perceptual biases. It wraps the high-performance C core library for
/// maximum portability and speed.
///
/// ## Quick Start
///
/// Create a journey from a single anchor color:
/// ```swift
/// let journey = ColorJourney(
///     config: .singleAnchor(
///         ColorJourneyRGB(red: 0.3, green: 0.5, blue: 0.8),
///         style: .balanced
///     )
/// )
///
/// // Sample a single color
/// let color = journey.sample(at: 0.5)
///
/// // Generate a discrete palette
/// let palette = journey.discrete(count: 8)
/// ```
///
/// ## Continuous vs Discrete Sampling
///
/// - **Continuous sampling** (`sample(at:)`): Returns a color at any parameter value [0, 1].
///   Useful for gradients, animations, and smooth transitions.
/// - **Discrete generation** (`discrete(count:)`): Returns N distinct colors with enforced
///   perceptual contrast. Useful for UI color sets, category labels, and timelines.
///
/// ## Architecture
///
/// ColorJourney uses a two-layer architecture:
/// 1. **C Core** (`CColorJourney`): High-performance color math, ~0.6μs per sample
/// 2. **Swift Wrapper** (`ColorJourney`): Type-safe, ergonomic API with preset styles
///
/// The C core ensures portability across iOS, macOS, watchOS, tvOS, visionOS, and beyond.
/// All color math operates in OKLab perceptual space for consistent, predictable results.
///
/// ## Memory Management
///
/// Automatically handles allocation and deallocation of the underlying C journey handle.
/// Create, use, and release via normal Swift ARC.
///
/// - SeeAlso: ``ColorJourneyConfig`` for configuration options
/// - SeeAlso: ``JourneyStyle`` for preset combinations
public final class ColorJourney {
    private var handle: OpaquePointer?

    /// Initialize a color journey from a configuration.
    ///
    /// Creates a journey handle from the provided configuration. The journey is
    /// immediately ready for sampling.
    ///
    /// - Parameter config: `ColorJourneyConfig` specifying anchor colors, biases, and behavior
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = ColorJourneyConfig(
    ///     anchors: [ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)],
    ///     lightness: .lighter,
    ///     chroma: .vivid,
    ///     contrast: .high
    /// )
    /// let journey = ColorJourney(config: config)
    /// ```
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

    /// Sample a continuous color from the journey at parameter t.
    ///
    /// Returns the color at position `t` ∈ [0, 1] along the journey. Useful for
    /// generating smooth gradients or animated color transitions.
    ///
    /// - Parameter parameterT: Position along the journey [0, 1]
    ///   - 0.0 = color at journey start
    ///   - 0.5 = color at journey midpoint
    ///   - 1.0 = color at journey end
    ///
    ///   Values outside [0, 1] are handled according to `loopMode`:
    ///   - `.open`: Clamped to [0, 1]
    ///   - `.closed`: Wrapped (seamless loop)
    ///   - `.pingPong`: Reflected (reverses direction)
    ///
    /// - Returns: `ColorJourneyRGB` color at parameter t
    ///
    /// ## Performance
    ///
    /// ~0.6 microseconds per sample (M1 hardware), optimized for real-time use.
    /// No allocations; safe to call thousands of times.
    ///
    /// ## Determinism
    ///
    /// Deterministic: identical parameters always produce identical output
    /// (unless seeded variation is enabled).
    ///
    /// ## Example (Smooth Gradient)
    ///
    /// ```swift
    /// let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    ///
    /// // Sample at regular intervals for a smooth gradient
    /// var colors: [ColorJourneyRGB] = []
    /// for i in 0..<20 {
    ///     let t = Float(i) / 19.0
    ///     colors.append(journey.sample(at: t))
    /// }
    /// ```
    ///
    /// - SeeAlso: ``discrete(count:)`` for palette generation
    /// - SeeAlso: ``LoopMode`` for boundary behavior
    public func sample(at parameterT: Float) -> ColorJourneyRGB {
        guard let handle = handle else {
            return ColorJourneyRGB(red: 0, green: 0, blue: 0)
        }

        let rgb = cj_journey_sample(handle, parameterT)
        return ColorJourneyRGB(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    /// Generate N discrete, perceptually distinct colors from the journey.
    ///
    /// Samples the journey at evenly-spaced parameters and enforces minimum
    /// perceptual contrast (OKLab ΔE) between adjacent colors. Returns an array
    /// of colors suitable for UI elements, timelines, category labels, etc.
    ///
    /// ## Contrast Enforcement
    ///
    /// Adjacent colors automatically meet the configured contrast threshold.
    /// If they don't, their lightness and chroma are adjusted slightly to ensure
    /// distinction while preserving the overall palette character.
    ///
    /// - Parameter count: Number of colors to generate (≥ 1)
    ///
    /// - Returns: Array of `count` distinct colors in sRGB
    ///
    /// ## Performance
    ///
    /// ~0.1 ms for 100 colors (M1 hardware). Scales linearly with count.
    ///
    /// ## Example (UI Palette)
    ///
    /// ```swift
    /// let journey = ColorJourney(
    ///     config: .singleAnchor(
    ///         ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
    ///         style: .balanced
    ///     )
    /// )
    ///
    /// let palette = journey.discrete(count: 8)
    /// for (i, color) in palette.enumerated() {
    ///     print("Color \(i): \(color.color)")  // Distinct UI colors
    /// }
    /// ```
    ///
    /// - SeeAlso: ``sample(at:)`` for continuous sampling
    /// - SeeAlso: ``ContrastLevel`` for contrast configuration
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

// MARK: - Convenience Extensions

#if canImport(SwiftUI)
extension ColorJourney {
    /// Create a SwiftUI gradient from the journey.
    ///
    /// Samples the journey at N stops and creates a SwiftUI Gradient object
    /// suitable for use with SwiftUI gradient views.
    ///
    /// - Parameter stops: Number of color stops in the gradient (default: 10)
    ///
    /// - Returns: SwiftUI `Gradient` ready for use in SwiftUI views
    ///
    /// ## Example
    ///
    /// ```swift
    /// let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    ///
    /// Rectangle()
    ///     .fill(journey.gradient(stops: 20))
    ///     .frame(height: 100)
    /// ```
    ///
    /// - SeeAlso: ``linearGradient(stops:startPoint:endPoint:)``
    public func gradient(stops: Int = 10) -> Gradient {
        let colors = (0..<stops).map { index in
            sample(at: Float(index) / Float(stops - 1)).color
        }
        return Gradient(colors: colors)
    }

    /// Create a SwiftUI LinearGradient from the journey.
    ///
    /// Samples the journey at N stops and creates a SwiftUI LinearGradient
    /// suitable for use directly in SwiftUI views. Customizable start and end points.
    ///
    /// - Parameters:
    ///   - stops: Number of color stops (default: 10)
    ///   - startPoint: Gradient start point (default: `.leading`)
    ///   - endPoint: Gradient end point (default: `.trailing`)
    ///
    /// - Returns: SwiftUI `LinearGradient` ready for view filling
    ///
    /// ## Example
    ///
    /// ```swift
    /// let journey = ColorJourney(config: .singleAnchor(baseColor, style: .balanced))
    ///
    /// VStack {
    ///     Rectangle()
    ///         .fill(journey.linearGradient(stops: 20))
    ///
    ///     Rectangle()
    ///         .fill(journey.linearGradient(stops: 20, startPoint: .topLeading, endPoint: .bottomTrailing))
    /// }
    /// ```
    ///
    /// - SeeAlso: ``gradient(stops:)``
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
    /// Initialize a SwiftUI Color from a ColorJourneyRGB.
    ///
    /// - Parameter journeyRGB: Color in ColorJourney RGB format
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
