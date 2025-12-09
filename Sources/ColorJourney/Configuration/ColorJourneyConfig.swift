import Foundation
import CColorJourney

// MARK: - Journey Configuration

/// Complete configuration for generating a color journey.
///
/// Specify anchor colors, perceptual biases, looping behavior, and optional variation.
/// Use preset builders for quick setup or customize all parameters.
///
/// ## Quick Start
///
/// ```swift
/// // Single anchor with preset style
/// let config = ColorJourneyConfig.singleAnchor(
///     ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
///     style: .balanced
/// )
///
/// // Or fully customized
/// let config = ColorJourneyConfig(
///     anchors: [color1, color2],
///     lightness: .lighter,
///     chroma: .vivid,
///     contrast: .high
/// )
/// ```
public struct ColorJourneyConfig {
    /// Color anchor point(s)
    public var anchors: [ColorJourneyRGB]
    /// Overall brightness adjustment
    public var lightness: LightnessBias
    /// Saturation adjustment
    public var chroma: ChromaBias
    /// Minimum color separation
    public var contrast: ContrastLevel
    /// Energy at journey center [0, 1]
    public var midJourneyVibrancy: Float
    /// Warm/cool hue shift
    public var temperature: TemperatureBias
    /// Boundary behavior (open, closed, pingpong)
    public var loopMode: LoopMode
    /// Deterministic variation config
    public var variation: VariationConfig

    /// Create a fully custom configuration.
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

    // MARK: - Preset Builders

    /// Single-anchor journey with preset style.
    ///
    /// Rotates around the hue wheel from a base color for full spectrum variations.
    ///
    /// ```swift
    /// let config = ColorJourneyConfig.singleAnchor(
    ///     baseColor,
    ///     style: .vividLoop
    /// )
    /// ```
    public static func singleAnchor(
        _ color: ColorJourneyRGB,
        style: JourneyStyle = .balanced
    ) -> ColorJourneyConfig {
        style.apply(to: ColorJourneyConfig(anchors: [color]))
    }

    /// Multi-anchor journey with preset style.
    ///
    /// Interpolates between multiple colors for controlled transitions.
    ///
    /// ```swift
    /// let config = ColorJourneyConfig.multiAnchor(
    ///     [red, green, blue],
    ///     style: .balanced
    /// )
    /// ```
    public static func multiAnchor(
        _ colors: [ColorJourneyRGB],
        style: JourneyStyle = .balanced
    ) -> ColorJourneyConfig {
        style.apply(to: ColorJourneyConfig(anchors: colors))
    }
}
