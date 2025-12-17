import SwiftUI
import ColorJourney

/// View for handling large palette requests with warnings and safe display modes.
///
/// Provides guidance for large palettes, paged/grouped display for palettes
/// above thresholds, and refuses requests beyond the absolute maximum.
struct LargePaletteView: View {
    @StateObject private var viewModel = LargePaletteViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Request controls
                requestSection
                
                // Advisory/Warning
                advisorySection
                
                // Results (if generated)
                if viewModel.showResults {
                    resultsSection
                }
            }
            .padding(32)
        }
        .background(Color(white: 0.1))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Large Palettes")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.primary)
            
            Text("Explore large color sets with performance guidance and safe display modes.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Request
    
    private var requestSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Palette size input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Palette Size")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Count", value: $viewModel.requestedCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Stepper("", value: $viewModel.requestedCount, in: 1...500)
                            .labelsHidden()
                        
                        // Quick presets
                        ForEach([50, 100, 150, 200], id: \.self) { preset in
                            Button("\(preset)") {
                                viewModel.requestedCount = preset
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.requestedCount == preset ? .blue : .gray)
                        }
                    }
                }
                
                Spacer()
                
                // Generate button
                Button(action: viewModel.generatePalette) {
                    HStack {
                        Image(systemName: viewModel.canGenerate ? "paintpalette.fill" : "exclamationmark.triangle.fill")
                        Text(viewModel.canGenerate ? "Generate" : "Cannot Generate")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.canGenerate ? .blue : .red)
                .disabled(!viewModel.canGenerate)
            }
            
            // Threshold indicators
            thresholdIndicators
        }
        .padding(20)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var thresholdIndicators: some View {
        HStack(spacing: 4) {
            thresholdBar
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Requested: \(viewModel.requestedCount)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(viewModel.statusColor)
                
                Text(viewModel.statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var thresholdBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.2))
                
                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(viewModel.statusColor)
                    .frame(width: min(CGFloat(viewModel.requestedCount) / CGFloat(RequestLimits.absoluteMaximum) * geometry.size.width, geometry.size.width))
                
                // Markers
                thresholdMarker(at: CGFloat(RequestLimits.warningThreshold) / CGFloat(RequestLimits.absoluteMaximum), label: "\(RequestLimits.warningThreshold)", geometry: geometry)
                thresholdMarker(at: CGFloat(RequestLimits.recommendedMaximum) / CGFloat(RequestLimits.absoluteMaximum), label: "\(RequestLimits.recommendedMaximum)", geometry: geometry)
                thresholdMarker(at: 1.0, label: "\(RequestLimits.absoluteMaximum)", geometry: geometry)
            }
        }
        .frame(height: 24)
    }
    
    private func thresholdMarker(at position: CGFloat, label: String, geometry: GeometryProxy) -> some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 1, height: 16)
            
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .position(x: position * geometry.size.width, y: 12)
    }
    
    // MARK: - Advisory
    
    private var advisorySection: some View {
        Group {
            if viewModel.requestedCount > RequestLimits.absoluteMaximum {
                AdvisoryBox(
                    type: .error,
                    title: "Request Denied",
                    message: "Cannot generate more than \(RequestLimits.absoluteMaximum) colors. The UI cannot reliably display this many swatches.",
                    technicalDetails: "Maximum supported: \(RequestLimits.absoluteMaximum)\nRequested: \(viewModel.requestedCount)\n\nConsider:\n- Splitting into multiple palettes\n- Using the discrete(range:) API for batch access\n- Sampling at intervals for preview",
                    actionTitle: "Set to Maximum",
                    onAction: { viewModel.requestedCount = RequestLimits.absoluteMaximum }
                )
            } else if viewModel.requestedCount > RequestLimits.recommendedMaximum {
                AdvisoryBox(
                    type: .warning,
                    title: "Large Palette Warning",
                    message: "Palettes with more than \(RequestLimits.recommendedMaximum) colors may affect UI responsiveness. Consider using paged display.",
                    technicalDetails: "Generation time: ~\(String(format: "%.2f", Double(viewModel.requestedCount) * 0.6))μs\nMemory: ~\(viewModel.requestedCount * 12) bytes\nRecommended for large sets: Use discrete(range:) for batch processing"
                )
            } else if viewModel.requestedCount > RequestLimits.warningThreshold {
                AdvisoryBox(
                    type: .info,
                    title: "Performance Note",
                    message: "Palettes above \(RequestLimits.warningThreshold) colors will use grouped display for better performance.",
                    technicalDetails: "ColorJourney generates ~1.6M colors/second\nYour request: ~\(String(format: "%.2f", Double(viewModel.requestedCount) * 0.6))μs"
                )
            } else {
                AdvisoryBox.info(
                    title: "Standard Palette",
                    message: "This palette size is optimal for UI display and performance."
                )
            }
        }
    }
    
    // MARK: - Results
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Generated Palette")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let timing = viewModel.generationTiming {
                    Text(timing)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                // Display mode toggle
                Picker("Display", selection: $viewModel.displayMode) {
                    Text("Grid").tag(DisplayMode.grid)
                    Text("Paged").tag(DisplayMode.paged)
                    Text("Grouped").tag(DisplayMode.grouped)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // Display based on mode
            switch viewModel.displayMode {
            case .grid:
                gridDisplay
            case .paged:
                pagedDisplay
            case .grouped:
                groupedDisplay
            }
        }
    }
    
    private var gridDisplay: some View {
        SwatchGrid(
            swatches: viewModel.displaySwatches,
            backgroundColor: Color(white: 0.15),
            showLabels: viewModel.displaySwatches.count <= 50
        )
    }
    
    private var pagedDisplay: some View {
        VStack(spacing: 16) {
            // Page indicator
            HStack {
                Button(action: viewModel.previousPage) {
                    Image(systemName: "chevron.left")
                }
                .disabled(viewModel.currentPage == 0)
                
                Text("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                    .font(.caption)
                
                Button(action: viewModel.nextPage) {
                    Image(systemName: "chevron.right")
                }
                .disabled(viewModel.currentPage >= viewModel.totalPages - 1)
            }
            
            SwatchGrid(
                swatches: viewModel.currentPageSwatches,
                backgroundColor: Color(white: 0.15),
                showLabels: true
            )
        }
    }
    
    private var groupedDisplay: some View {
        VStack(spacing: 16) {
            ForEach(Array(viewModel.groupedSwatches.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Group \(index + 1) (Colors \(index * viewModel.groupSize + 1)-\(min((index + 1) * viewModel.groupSize, viewModel.totalColors)))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    SwatchGrid(
                        swatches: group,
                        backgroundColor: Color(white: 0.15),
                        showLabels: true
                    )
                }
            }
        }
    }
}

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable {
    case grid = "Grid"
    case paged = "Paged"
    case grouped = "Grouped"
}

// MARK: - Preview

#Preview("Large Palette") {
    LargePaletteView()
        .frame(width: 900, height: 800)
}
