import SwiftUI
import ColorJourney

/// View for comparing code and CSS usage examples with adjustable parameters.
///
/// Shows how to consume generated colors in Swift code and CSS, with
/// live updates and copy functionality.
struct UsageExamplesView: View {
    @StateObject private var viewModel = UsageExamplesViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Quick settings
                quickSettingsSection
                
                // Preview swatches
                previewSection
                
                // Code examples
                codeExamplesSection
            }
            .padding(32)
        }
        .background(Color(white: 0.1))
        .onAppear {
            viewModel.generateExamples()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usage Examples")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.primary)
            
            Text("Copy ready-to-use code snippets for Swift and CSS integration.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Quick Settings
    
    private var quickSettingsSection: some View {
        HStack(spacing: 24) {
            // Color count
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Picker("Count", selection: $viewModel.colorCount) {
                    Text("4").tag(4)
                    Text("8").tag(8)
                    Text("12").tag(12)
                    Text("16").tag(16)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.colorCount) { _, _ in
                    viewModel.generateExamples()
                }
            }
            
            // Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Style")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Picker("Style", selection: $viewModel.selectedStyle) {
                    Text("Balanced").tag("balanced")
                    Text("Vivid").tag("vividLoop")
                    Text("Pastel").tag("pastelDrift")
                    Text("Night").tag("nightMode")
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedStyle) { _, _ in
                    viewModel.generateExamples()
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Preview
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                ForEach(viewModel.previewSwatches) { swatch in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(swatch.swiftUIColor)
                        .frame(height: 50)
                        .overlay(
                            Text(swatch.hexString)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(swatch.textColor)
                        )
                }
            }
        }
    }
    
    // MARK: - Code Examples
    
    private var codeExamplesSection: some View {
        VStack(spacing: 20) {
            // Swift Usage
            codeExampleCard(
                title: "Swift Integration",
                description: "Create a ColorJourney and generate your palette",
                snippet: viewModel.swiftUsageSnippet
            )
            
            // Swift Colors Array
            codeExampleCard(
                title: "Swift Color Array",
                description: "Direct color values for static use",
                snippet: viewModel.swiftColorsSnippet
            )
            
            // CSS (only if reasonable count)
            if viewModel.colorCount <= 20 {
                codeExampleCard(
                    title: "CSS Classes",
                    description: "Ready-to-use CSS class definitions",
                    snippet: viewModel.cssSnippet
                )
                
                codeExampleCard(
                    title: "CSS Custom Properties",
                    description: "CSS variables for theming flexibility",
                    snippet: viewModel.cssVariablesSnippet
                )
            } else {
                AdvisoryBox.info(
                    title: "CSS Not Available",
                    message: "CSS snippets are hidden for palettes larger than 20 colors to keep the output manageable."
                )
            }
        }
    }
    
    private func codeExampleCard(title: String, description: String, snippet: CodeSnippet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            CodeSnippetView(
                snippet: snippet,
                onCopy: { _ in viewModel.recordCopy() },
                maxLines: 15
            )
        }
    }
}

// MARK: - Preview

#Preview("Usage Examples") {
    UsageExamplesView()
        .frame(width: 800, height: 900)
}
