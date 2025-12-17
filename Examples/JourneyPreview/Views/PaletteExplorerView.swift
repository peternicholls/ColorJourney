import SwiftUI
import ColorJourney

/// Main palette exploration view for generating and visualizing color palettes.
///
/// Provides interactive controls for palette size, delta spacing, anchor color,
/// background, and swatch size. Shows live-updating swatches with advisory info
/// and copyable code snippets.
struct PaletteExplorerView: View {
    @StateObject private var viewModel = PaletteExplorerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Controls
                controlsSection
                
                // Advisory (if any)
                if let advisory = viewModel.currentAdvisory {
                    advisorySection(advisory)
                }
                
                // Swatches
                swatchSection
                
                // Code snippets
                codeSection
            }
            .padding(32)
        }
        .background(viewModel.backgroundColor.color.opacity(0.95))
        .onAppear {
            viewModel.generatePalette()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Palette Explorer")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.primary)
            
            Text("Generate perceptually uniform color palettes using ColorJourney's incremental algorithm.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                // Palette count
                controlGroup(title: "Palette Size") {
                    HStack {
                        Stepper(value: $viewModel.paletteCount, in: 1...RequestLimits.absoluteMaximum) {
                            Text("\(viewModel.paletteCount) colors")
                                .font(.system(.body, design: .monospaced))
                        }
                        .onChange(of: viewModel.paletteCount) { _, _ in
                            viewModel.generatePalette()
                        }
                    }
                }
                
                // Delta target
                controlGroup(title: "Delta Spacing") {
                    Picker("Delta", selection: $viewModel.deltaTarget) {
                        ForEach(DeltaTarget.allCases) { target in
                            Text(target.rawValue).tag(target)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.deltaTarget) { _, _ in
                        viewModel.generatePalette()
                    }
                }
            }
            
            HStack(spacing: 24) {
                // Style picker
                controlGroup(title: "Journey Style") {
                    Picker("Style", selection: $viewModel.selectedStyleName) {
                        ForEach(viewModel.availableStyles, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                    .onChange(of: viewModel.selectedStyleName) { _, _ in
                        viewModel.generatePalette()
                    }
                }
                
                // Swatch size
                controlGroup(title: "Swatch Size") {
                    Slider(
                        value: $viewModel.swatchSizeValue,
                        in: 0...3,
                        step: 1
                    ) {
                        Text("Size")
                    } minimumValueLabel: {
                        Image(systemName: "square.grid.4x3.fill")
                            .font(.caption)
                    } maximumValueLabel: {
                        Image(systemName: "square.fill")
                            .font(.caption)
                    }
                }
            }
            
            HStack(spacing: 24) {
                // Anchor color
                controlGroup(title: "Anchor Color") {
                    ColorPicker("Anchor", selection: $viewModel.anchorSwiftUIColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: viewModel.anchorSwiftUIColor) { _, _ in
                            viewModel.generatePalette()
                        }
                }
                
                // Background color
                controlGroup(title: "Background") {
                    HStack(spacing: 8) {
                        ForEach(viewModel.backgroundPresets, id: \.self) { preset in
                            backgroundPresetButton(preset)
                        }
                        ColorPicker("Custom", selection: $viewModel.backgroundSwiftUIColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func controlGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func backgroundPresetButton(_ preset: Color) -> some View {
        Button(action: { viewModel.backgroundSwiftUIColor = preset }) {
            Circle()
                .fill(preset)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(
                            viewModel.backgroundSwiftUIColor == preset ? Color.blue : Color.white.opacity(0.3),
                            lineWidth: viewModel.backgroundSwiftUIColor == preset ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Advisory
    
    private func advisorySection(_ advisory: AdvisoryInfo) -> some View {
        AdvisoryBox(
            type: advisory.type,
            title: advisory.title,
            message: advisory.message,
            technicalDetails: advisory.technicalDetails
        )
    }
    
    // MARK: - Swatches
    
    private var swatchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Generated Palette")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let timing = viewModel.generationTiming {
                    Text(timing)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            SwatchGrid(
                swatches: viewModel.swatches,
                backgroundColor: viewModel.backgroundSwiftUIColor,
                showLabels: viewModel.paletteCount <= 50,
                onSwatchTapped: { swatch in
                    viewModel.selectedSwatchIndex = swatch.index
                }
            )
        }
    }
    
    // MARK: - Code
    
    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Code Samples")
                .font(.headline)
                .foregroundColor(.primary)
            
            MultiCodeSnippetView(
                snippets: viewModel.codeSnippets,
                onCopy: { snippet in
                    viewModel.recordCopy(snippet: snippet)
                }
            )
        }
    }
}

// MARK: - Preview

#Preview("Palette Explorer") {
    PaletteExplorerView()
        .frame(width: 900, height: 800)
}
