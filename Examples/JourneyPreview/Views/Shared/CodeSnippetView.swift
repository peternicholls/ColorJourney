import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// A view for displaying code snippets with syntax highlighting and copy functionality.
///
/// Supports multiple languages (Swift, CSS) with copy-to-clipboard and confirmation feedback.
struct CodeSnippetView: View {
    /// The code snippet to display
    let snippet: CodeSnippet
    
    /// Callback when copy is triggered
    var onCopy: ((CodeSnippet) -> Void)?
    
    /// Maximum lines to show before truncating (nil for all)
    var maxLines: Int? = nil
    
    /// Whether the view is in compact mode
    var isCompact: Bool = false
    
    // MARK: - Private State
    
    @State private var copyState: CopyState = .idle
    @State private var isExpanded: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            // Code content
            codeContentView
        }
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Language badge
            Text(snippet.type.displayTitle)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Spacer()
            
            // Copy button
            copyButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.08))
    }
    
    private var copyButton: some View {
        Button(action: performCopy) {
            HStack(spacing: 4) {
                Image(systemName: copyIconName)
                    .font(.system(size: 12, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
                
                if !isCompact {
                    Text(copyButtonText)
                        .font(.caption.weight(.medium))
                        .contentTransition(.numericText())
                }
            }
            .foregroundColor(copyButtonColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(copyButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .animation(.easeInOut(duration: 0.2), value: copyState)
        }
        .buttonStyle(.plain)
        .disabled(copyState.isCopying)
    }
    
    private var copyIconName: String {
        switch copyState {
        case .idle: return "doc.on.doc"
        case .copying: return "arrow.clockwise"
        case .success: return "checkmark"
        case .failed: return "xmark"
        }
    }
    
    private var copyButtonText: String {
        switch copyState {
        case .idle: return "Copy"
        case .copying: return "Copying..."
        case .success: return "Copied!"
        case .failed: return "Failed"
        }
    }
    
    private var copyButtonColor: Color {
        switch copyState {
        case .idle: return .primary
        case .copying: return .secondary
        case .success: return .green
        case .failed: return .red
        }
    }
    
    private var copyButtonBackground: Color {
        switch copyState {
        case .success: return Color.green.opacity(0.2)
        case .failed: return Color.red.opacity(0.2)
        default: return Color.white.opacity(0.1)
        }
    }
    
    // MARK: - Code Content
    
    private var codeContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                let lines = displayLines
                
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: 0) {
                        // Line number
                        Text("\(index + 1)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                            .frame(width: 30, alignment: .trailing)
                            .padding(.trailing, 12)
                        
                        // Code line
                        Text(line)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 2)
                }
                
                // Show more button if truncated
                if isTruncated && !isExpanded {
                    showMoreButton
                }
            }
            .padding(12)
        }
    }
    
    private var displayLines: [String] {
        let allLines = snippet.code.components(separatedBy: "\n")
        
        guard let maxLines = maxLines, !isExpanded else {
            return allLines
        }
        
        if allLines.count > maxLines {
            return Array(allLines.prefix(maxLines))
        }
        return allLines
    }
    
    private var isTruncated: Bool {
        guard let maxLines = maxLines else { return false }
        return snippet.code.components(separatedBy: "\n").count > maxLines
    }
    
    private var showMoreButton: some View {
        Button(action: { isExpanded = true }) {
            HStack {
                Text("Show all \(snippet.code.components(separatedBy: "\n").count) lines")
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func performCopy() {
        copyState = .copying
        
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(snippet.code, forType: .string)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            copyState = success ? .success : .failed("Clipboard access denied")
            onCopy?(snippet)
            
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if copyState.isSuccess || !copyState.isCopying {
                    copyState = .idle
                }
            }
        }
        #else
        copyState = .failed("Clipboard not available")
        #endif
    }
}

// MARK: - Multi-Snippet View

/// A tabbed view for displaying multiple code snippets (e.g., Swift + CSS)
struct MultiCodeSnippetView: View {
    /// Available snippets
    let snippets: [CodeSnippet]
    
    /// Callback when copy is triggered
    var onCopy: ((CodeSnippet) -> Void)?
    
    // MARK: - State
    
    @State private var selectedSnippet: SnippetType
    
    init(snippets: [CodeSnippet], onCopy: ((CodeSnippet) -> Void)? = nil) {
        self.snippets = snippets
        self.onCopy = onCopy
        self._selectedSnippet = State(initialValue: snippets.first?.type ?? .swiftUsage)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 2) {
                ForEach(snippets) { snippet in
                    tabButton(for: snippet.type)
                }
                Spacer()
            }
            .padding(4)
            .background(Color(white: 0.08))
            
            // Selected snippet with transition
            if let snippet = snippets.first(where: { $0.type == selectedSnippet }) {
                CodeSnippetView(snippet: snippet, onCopy: onCopy)
                    .id(selectedSnippet)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.2), value: selectedSnippet)
    }
    
    private func tabButton(for type: SnippetType) -> some View {
        Button(action: { 
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSnippet = type 
            }
        }) {
            Text(type.displayTitle)
                .font(.caption.weight(.medium))
                .foregroundColor(selectedSnippet == type ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedSnippet == type
                        ? Color.white.opacity(0.1)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .animation(.easeInOut(duration: 0.15), value: selectedSnippet == type)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Code Snippet View") {
    let swiftSnippet = CodeSnippet(
        type: .swiftUsage,
        code: """
        import ColorJourney
        
        let journey = ColorJourney(
            config: .singleAnchor(
                ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
                style: .balanced
            )
        )
        
        let palette = journey.discrete(count: 8)
        """
    )
    
    let cssSnippet = CodeSnippet(
        type: .css,
        code: """
        /* Generated Palette */
        .color-0 { background-color: #8033CC; }
        .color-1 { background-color: #9040DD; }
        .color-2 { background-color: #A050EE; }
        """
    )
    
    VStack(spacing: 20) {
        CodeSnippetView(snippet: swiftSnippet)
        
        MultiCodeSnippetView(snippets: [swiftSnippet, cssSnippet])
    }
    .padding()
    .frame(width: 500)
    .background(Color(white: 0.15))
}
