import Foundation
import CColorJourney

// MARK: - Configuration Helpers

/// Maps Swift configuration to C core config.
internal class ConfigurationMapper {
    static func mapAnchors(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
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

    static func mapLightness(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
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

    static func mapChroma(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
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

    static func mapContrast(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
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

    static func mapTemperature(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.temperature {
        case .neutral:
            cConfig.temperature_bias = CJ_TEMPERATURE_NEUTRAL
        case .warm:
            cConfig.temperature_bias = CJ_TEMPERATURE_WARM
        case .cool:
            cConfig.temperature_bias = CJ_TEMPERATURE_COOL
        }
    }

    static func mapLoopMode(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
        switch config.loopMode {
        case .open:
            cConfig.loop_mode = CJ_LOOP_OPEN
        case .closed:
            cConfig.loop_mode = CJ_LOOP_CLOSED
        case .pingPong:
            cConfig.loop_mode = CJ_LOOP_PINGPONG
        }
    }

    static func mapVariation(_ cConfig: inout CJ_Config, from config: ColorJourneyConfig) {
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
}
