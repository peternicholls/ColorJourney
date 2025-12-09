import Foundation
import CColorJourney

// MARK: - Journey Styles (Presets)

/// Pre-tuned combinations of perceptual biases for common use cases.
///
/// Each style delivers good results without manual parameter tuning.
/// Combine with single or multi-anchor configurations.
///
/// - `.balanced`: Neutral on all dimensions. Safe, versatile default.
/// - `.pastelDrift`: Light, muted, soft contrast. Soft and sophisticated.
/// - `.vividLoop`: Saturated, high-contrast, seamless loop for color wheels.
/// - `.nightMode`: Dark, subdued colors. Ideal for dark UIs.
/// - `.warmEarth`: Warm hues with natural, earthy character.
/// - `.coolSky`: Cool hues, light and airy. Professional, calm.
/// - `.custom(...)`: Manually specify all four perceptual dimensions.
///
/// ## Example
///
/// ```swift
/// let journey = ColorJourney(
///     config: .singleAnchor(baseColor, style: .vividLoop)
/// )
/// ```
public enum JourneyStyle {
    case balanced
    case pastelDrift
    case vividLoop
    case nightMode
    case warmEarth
    case coolSky
    /// Manually configure lightness, chroma, contrast, and temperature
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
