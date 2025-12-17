import SwiftUI

/// A styled box for displaying advisory information, warnings, and technical details.
///
/// Used to provide contextual guidance and performance notes to users.
struct AdvisoryBox: View {
    /// The type of advisory (info, warning, error, success)
    let type: AdvisoryType
    
    /// Title of the advisory
    let title: String
    
    /// Detailed message content
    let message: String
    
    /// Optional technical details (shown in a collapsible section)
    var technicalDetails: String? = nil
    
    /// Optional action button
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil
    
    /// Whether to show the dismiss button
    var isDismissable: Bool = false
    var onDismiss: (() -> Void)? = nil
    
    // MARK: - Private State
    
    @State private var showTechnicalDetails = false
    @State private var isVisible = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 10) {
                Image(systemName: type.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(type.iconColor)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5), value: type == .warning || type == .error)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isDismissable {
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Technical details (collapsible)
            if let details = technicalDetails {
                DisclosureGroup(
                    isExpanded: $showTechnicalDetails,
                    content: {
                        Text(details)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    },
                    label: {
                        Text("Technical Details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: showTechnicalDetails)
            }
            
            // Action button
            if let actionTitle = actionTitle {
                Button(action: { onAction?() }) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(type.buttonTint)
            }
        }
        .padding(16)
        .background(type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(type.borderColor, lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Advisory Types

/// Types of advisory messages with associated styling
enum AdvisoryType {
    case info
    case warning
    case error
    case success
    case performance
    
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .success: return "checkmark.circle.fill"
        case .performance: return "gauge.with.needle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        case .performance: return .purple
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .info: return Color.blue.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .error: return Color.red.opacity(0.1)
        case .success: return Color.green.opacity(0.1)
        case .performance: return Color.purple.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .info: return Color.blue.opacity(0.3)
        case .warning: return Color.orange.opacity(0.3)
        case .error: return Color.red.opacity(0.3)
        case .success: return Color.green.opacity(0.3)
        case .performance: return Color.purple.opacity(0.3)
        }
    }
    
    var buttonTint: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        case .performance: return .purple
        }
    }
}

// MARK: - Convenience Initializers

extension AdvisoryBox {
    /// Create an info advisory
    static func info(title: String, message: String, details: String? = nil) -> AdvisoryBox {
        AdvisoryBox(type: .info, title: title, message: message, technicalDetails: details)
    }
    
    /// Create a warning advisory
    static func warning(title: String, message: String, details: String? = nil) -> AdvisoryBox {
        AdvisoryBox(type: .warning, title: title, message: message, technicalDetails: details)
    }
    
    /// Create an error advisory
    static func error(title: String, message: String, details: String? = nil) -> AdvisoryBox {
        AdvisoryBox(type: .error, title: title, message: message, technicalDetails: details)
    }
    
    /// Create a performance advisory
    static func performance(title: String, message: String, details: String? = nil) -> AdvisoryBox {
        AdvisoryBox(type: .performance, title: title, message: message, technicalDetails: details)
    }
}

// MARK: - Preview

#Preview("Advisory Boxes") {
    ScrollView {
        VStack(spacing: 16) {
            AdvisoryBox.info(
                title: "About Delta Spacing",
                message: "Delta (ΔE) controls the perceptual distance between colors. Higher values create more distinct colors.",
                details: "ΔE range: [0.02, 0.05]\nAlgorithm: OKLab perceptual distance"
            )
            
            AdvisoryBox.warning(
                title: "Large Palette",
                message: "You've requested 75 colors. This may affect rendering performance.",
                details: "Recommended: ≤50 colors\nMaximum: 200 colors"
            )
            
            AdvisoryBox.error(
                title: "Request Denied",
                message: "Cannot generate more than 200 colors. Consider batching your request."
            )
            
            AdvisoryBox.performance(
                title: "Generation Complete",
                message: "50 colors generated in 0.03ms (0.6μs/color)"
            )
        }
        .padding()
    }
    .frame(width: 400)
    .background(Color(white: 0.15))
}
