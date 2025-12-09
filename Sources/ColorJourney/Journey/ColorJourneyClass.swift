import Foundation
import CColorJourney

// MARK: - Color Journey

/// Generate color palettes using perceptually uniform color math.
///
/// `ColorJourney` creates palettes from anchor colors and perceptual biases.
/// Sample continuously for smooth gradients or generate discrete colors for UI palettes.
///
/// ## Quick Start
///
/// ```swift
/// // Create a journey
/// let journey = ColorJourney(
///     config: .singleAnchor(baseColor, style: .balanced)
/// )
///
/// // Sample continuously
/// let midColor = journey.sample(at: 0.5)
///
/// // Generate discrete palette
/// let palette = journey.discrete(count: 8)
/// ```
///
/// ## Continuous vs Discrete
///
/// - **`sample(at:)`**: Get any color along [0, 1]. Use for smooth gradients.
/// - **`discrete(count:)`**: Get N distinct colors with enforced contrast. Use for UI palettes.
///
/// ## Performance
///
/// ~0.6 μs per sample. Memory-safe and deterministic (unless variation enabled).
///
/// - SeeAlso: ``ColorJourneyConfig`` for configuration options
/// - SeeAlso: ``JourneyStyle`` for preset styles
public final class ColorJourney {
    private var handle: OpaquePointer?

    /// Create a journey from configuration.
    ///
    /// ```swift
    /// let config = ColorJourneyConfig.singleAnchor(color, style: .balanced)
    /// let journey = ColorJourney(config: config)
    /// ```
    public init(config: ColorJourneyConfig) {
        var cConfig = CJ_Config()
        cj_config_init(&cConfig)

        cConfig.mid_journey_vibrancy = config.midJourneyVibrancy

        ConfigurationMapper.mapAnchors(&cConfig, from: config)
        ConfigurationMapper.mapLightness(&cConfig, from: config)
        ConfigurationMapper.mapChroma(&cConfig, from: config)
        ConfigurationMapper.mapContrast(&cConfig, from: config)
        ConfigurationMapper.mapTemperature(&cConfig, from: config)
        ConfigurationMapper.mapLoopMode(&cConfig, from: config)
        ConfigurationMapper.mapVariation(&cConfig, from: config)

        handle = cj_journey_create(&cConfig)
    }

    deinit {
        if let handle = handle {
            cj_journey_destroy(handle)
        }
    }

    /// Sample a single color at position t ∈ [0, 1].
    ///
    /// Use for smooth gradients, animations, and transitions.
    ///
    /// - Parameter parameterT: Position [0 = start, 1 = end]
    ///   - Values outside [0, 1] are handled per `loopMode`
    ///   - `.open`: Clamped to [0, 1]
    ///   - `.closed`: Wraps seamlessly
    ///   - `.pingPong`: Reverses at endpoints
    ///
    /// - Returns: Color at position t
    ///
    /// ## Example
    ///
    /// ```swift
    /// for i in 0..<20 {
    ///     let t = Float(i) / 19
    ///     let color = journey.sample(at: t)
    /// }
    /// ```
    ///
    /// - SeeAlso: ``discrete(count:)``
    public func sample(at parameterT: Float) -> ColorJourneyRGB {
        guard let handle = handle else {
            return ColorJourneyRGB(red: 0, green: 0, blue: 0)
        }

        let rgb = cj_journey_sample(handle, parameterT)
        return ColorJourneyRGB(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    /// Generate N discrete, perceptually distinct colors.
    ///
    /// Use for UI palettes, category labels, and timelines. Automatically enforces
    /// minimum contrast between adjacent colors per configuration.
    ///
    /// - Parameter count: Number of colors to generate (≥ 1)
    ///
    /// - Returns: Array of distinct colors
    ///
    /// ## Example
    ///
    /// ```swift
    /// let palette = journey.discrete(count: 8)
    /// for (i, color) in palette.enumerated() {
    ///     print("Color \(i): \(color.color)")
    /// }
    /// ```
    ///
    /// - SeeAlso: ``sample(at:)``
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
