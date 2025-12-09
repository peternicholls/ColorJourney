import Foundation

// MARK: - Lightness Bias

/// Shift palette brightness toward lighter or darker tones.
///
/// Adjusts overall brightness without changing hue or saturation, useful for
/// adapting palettes to light or dark UI backgrounds.
///
/// - `.neutral`: No adjustment
/// - `.lighter`: Shift toward brighter colors (~+20%)
/// - `.darker`: Shift toward darker colors (~-20%)
/// - `.custom(weight:)`: Manual adjustment [-1 = darkest, 0 = neutral, +1 = lightest]
public enum LightnessBias {
    case neutral
    case lighter
    case darker
    /// Custom lightness weight [-1.0, 1.0]
    case custom(weight: Float)
}

// MARK: - Chroma Bias

/// Adjust color saturation (soft pastels to vivid brights).
///
/// Scales saturation without changing brightness or hue. Creates distinctly
/// different emotional tones.
///
/// - `.neutral`: No adjustment
/// - `.muted`: Soften colors (×0.6) for pastel palettes
/// - `.vivid`: Saturate colors (×1.4) for bold, vibrant palettes
/// - `.custom(multiplier:)`: Manual scaling [0.5 = half, 2.0 = double]
public enum ChromaBias {
    case neutral
    case muted
    case vivid
    /// Custom saturation multiplier [0.5, 2.0]
    case custom(multiplier: Float)
}

// MARK: - Contrast Level

/// Minimum perceptual distance between adjacent colors.
///
/// Ensures colors in discrete palettes are distinguishable, critical for accessible UIs.
/// Automatically adjusts lightness/saturation to meet thresholds while preserving
/// the overall palette character.
///
/// - `.low`: Subtle separation (ΔE ≥ 0.05) for soft, harmonious palettes
/// - `.medium`: Balanced separation (ΔE ≥ 0.10), recommended default
/// - `.high`: Strong distinction (ΔE ≥ 0.15) for high accessibility
/// - `.custom(threshold:)`: Custom OKLab perceptual distance threshold
public enum ContrastLevel {
    case low
    case medium
    case high
    /// Custom perceptual distance (OKLab ΔE) [0.05, 0.20]
    case custom(threshold: Float)
}

// MARK: - Temperature Bias

/// Shift hue toward warm (reds/oranges) or cool (blues/cyans) tones.
///
/// Rotates hue without changing brightness or saturation. Affects emotional
/// response—warm feels comforting, cool feels calm.
///
/// - `.neutral`: No hue shift
/// - `.warm`: Shift toward red/orange (~+17°)
/// - `.cool`: Shift toward blue/cyan (~-17°)
public enum TemperatureBias {
    case neutral
    case warm
    case cool
}

// MARK: - Loop Mode

/// How the journey behaves at boundaries (t=0 and t=1).
///
/// Controls sampling behavior when t is outside [0, 1].
///
/// - `.open`: One-way journey, useful for linear gradients and progressions
/// - `.closed`: Seamless loop, useful for circular/cyclic UI elements
/// - `.pingPong`: Reversal (0→1→0), useful for animations
public enum LoopMode {
    case open
    case closed
    case pingPong
}

// MARK: - Variation Config

/// Seeded deterministic variation for discrete colors.
///
/// Adds subtle micro-changes to create organic appearance while remaining reproducible.
/// Same config + same seed = identical variation every time.
///
/// ```swift
/// let variation = VariationConfig(
///     enabled: true,
///     dimensions: [.hue, .lightness],
///     strength: .subtle,
///     seed: 0x123456789ABCDEF0
/// )
/// ```
public struct VariationConfig {
    /// Enable or disable variation
    public var enabled: Bool
    /// Which color axes to vary
    public var dimensions: VariationDimensions
    /// How strong the variation is
    public var strength: VariationStrength
    /// Seed for reproducibility
    public var seed: UInt64

    /// Create a variation configuration.
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

    /// Variation disabled (default).
    public static var off: VariationConfig {
        VariationConfig(enabled: false)
    }

    /// Create subtle variation with custom seed.
    ///
    /// ```swift
    /// let config = VariationConfig.subtle(dimensions: [.hue, .lightness], seed: 42)
    /// ```
    public static func subtle(dimensions: VariationDimensions, seed: UInt64? = nil) -> VariationConfig {
        VariationConfig(
            enabled: true,
            dimensions: dimensions,
            strength: .subtle,
            seed: seed ?? 0x123456789ABCDEF0
        )
    }
}

// MARK: - Variation Dimensions

/// Which color dimensions are subject to variation.
///
/// Combine multiple dimensions: `.hue`, `.lightness`, `.chroma`, or `.all`.
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

// MARK: - Variation Strength

/// Magnitude of seeded variation.
///
/// Higher values create more organic, "hand-crafted" appearance.
///
/// - `.subtle`: Barely noticeable (~1-2%)
/// - `.noticeable`: Visible but harmonious (~3-5%)
/// - `.custom(magnitude:)`: Custom strength [0.0 = none, 1.0 = maximum]
public enum VariationStrength {
    case subtle
    case noticeable
    /// Custom magnitude [0.0, 1.0]
    /// Use small values (0.05–0.2) for subtlety.
    case custom(magnitude: Float)
}
