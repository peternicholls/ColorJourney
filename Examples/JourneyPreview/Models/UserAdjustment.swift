import Foundation

/// Captures recent user input changes to drive live updates and advisory messaging.
///
/// Used by view models to track what changed and provide contextual feedback.
struct UserAdjustment: Equatable {
    /// Timestamp of the adjustment
    let timestamp: Date
    
    /// Type of control that was adjusted
    let controlType: ControlType
    
    /// Previous value (for comparison)
    let previousValue: AdjustmentValue
    
    /// New value after adjustment
    let newValue: AdjustmentValue
    
    /// Whether this adjustment requires regeneration
    var requiresRegeneration: Bool {
        switch controlType {
        case .paletteCount, .deltaTarget, .anchorColor, .style:
            return true
        case .swatchSize, .backgroundColor:
            return false
        }
    }
    
    /// Advisory message for this adjustment
    var advisoryMessage: String? {
        switch controlType {
        case .paletteCount:
            if case .integer(let newCount) = newValue {
                if newCount > RequestLimits.warningThreshold {
                    return "Large palettes (>\(RequestLimits.warningThreshold)) may affect UI performance"
                } else if newCount > RequestLimits.recommendedMaximum {
                    return "Consider using paged display for palettes >\(RequestLimits.recommendedMaximum) colors"
                }
            }
        case .deltaTarget:
            if case .deltaTarget(let target) = newValue {
                switch target {
                case .tight:
                    return "Tight spacing produces subtle color variations"
                case .wide:
                    return "Wide spacing maximizes color distinction"
                case .medium:
                    return nil
                }
            }
        default:
            return nil
        }
        return nil
    }
}

// MARK: - Control Types

/// Types of controls that can be adjusted
enum ControlType: String, CaseIterable {
    case paletteCount = "palette_count"
    case deltaTarget = "delta_target"
    case anchorColor = "anchor_color"
    case backgroundColor = "background_color"
    case swatchSize = "swatch_size"
    case style = "style"
    
    /// Display name for the control
    var displayName: String {
        switch self {
        case .paletteCount: return "Palette Size"
        case .deltaTarget: return "Delta Spacing"
        case .anchorColor: return "Anchor Color"
        case .backgroundColor: return "Background"
        case .swatchSize: return "Swatch Size"
        case .style: return "Style"
        }
    }
}

// MARK: - Adjustment Values

/// Wrapper for different adjustment value types
enum AdjustmentValue: Equatable {
    case integer(Int)
    case float(Float)
    case deltaTarget(DeltaTarget)
    case swatchSize(SwatchSizePreference)
    case style(String)
    case color(Float, Float, Float) // RGB
    
    /// String representation for display
    var displayString: String {
        switch self {
        case .integer(let value):
            return "\(value)"
        case .float(let value):
            return String(format: "%.2f", value)
        case .deltaTarget(let target):
            return target.rawValue
        case .swatchSize(let size):
            return size.rawValue
        case .style(let name):
            return name
        case .color(let r, let g, let b):
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }
}

// MARK: - Adjustment History

/// Tracks recent adjustments for undo/context
final class AdjustmentHistory: ObservableObject {
    /// Recent adjustments (most recent first)
    @Published private(set) var recentAdjustments: [UserAdjustment] = []
    
    /// Maximum history size
    let maxHistorySize: Int = 20
    
    /// Record a new adjustment
    func record(_ adjustment: UserAdjustment) {
        recentAdjustments.insert(adjustment, at: 0)
        if recentAdjustments.count > maxHistorySize {
            recentAdjustments.removeLast()
        }
    }
    
    /// Get the most recent adjustment
    var mostRecent: UserAdjustment? {
        recentAdjustments.first
    }
    
    /// Get the most recent advisory message
    var currentAdvisory: String? {
        mostRecent?.advisoryMessage
    }
    
    /// Clear history
    func clear() {
        recentAdjustments.removeAll()
    }
}
