import SwiftUI
import Combine
import ColorJourney

/// View model for the Large Palette view.
///
/// Manages large palette requests, warnings, and paged/grouped display.
@MainActor
final class LargePaletteViewModel: ObservableObject {
    // MARK: - Published State
    
    /// Requested color count
    @Published var requestedCount: Int = 50
    
    /// Current display mode
    @Published var displayMode: DisplayMode = .grid
    
    /// Current page (for paged display)
    @Published var currentPage: Int = 0
    
    /// Whether to show results
    @Published private(set) var showResults: Bool = false
    
    /// Generation timing
    @Published private(set) var generationTiming: String? = nil
    
    // MARK: - Private State
    
    private var generatedColors: [ColorJourneyRGB] = []
    private let defaultAnchor = ColorJourneyRGB(red: 0.4, green: 0.6, blue: 0.8)
    
    // MARK: - Constants
    
    let pageSize: Int = 25
    let groupSize: Int = 20
    
    // MARK: - Computed Properties
    
    /// Whether generation is allowed
    var canGenerate: Bool {
        requestedCount >= 1 && requestedCount <= RequestLimits.absoluteMaximum
    }
    
    /// Status color based on request size
    var statusColor: Color {
        if requestedCount > RequestLimits.absoluteMaximum {
            return .red
        } else if requestedCount > RequestLimits.recommendedMaximum {
            return .orange
        } else if requestedCount > RequestLimits.warningThreshold {
            return .yellow
        }
        return .green
    }
    
    /// Status description
    var statusDescription: String {
        if requestedCount > RequestLimits.absoluteMaximum {
            return "Exceeds maximum (\(RequestLimits.absoluteMaximum))"
        } else if requestedCount > RequestLimits.recommendedMaximum {
            return "Above recommended (\(RequestLimits.recommendedMaximum))"
        } else if requestedCount > RequestLimits.warningThreshold {
            return "Above standard (\(RequestLimits.warningThreshold))"
        }
        return "Optimal range"
    }
    
    /// Total colors generated
    var totalColors: Int {
        generatedColors.count
    }
    
    /// Total pages for paged display
    var totalPages: Int {
        (totalColors + pageSize - 1) / pageSize
    }
    
    /// Display swatches (all or limited based on mode)
    var displaySwatches: [SwatchDisplay] {
        SwatchDisplay.fromPalette(generatedColors, size: .small, showLabels: generatedColors.count <= 50)
    }
    
    /// Current page swatches for paged display
    var currentPageSwatches: [SwatchDisplay] {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, totalColors)
        
        guard startIndex < totalColors else { return [] }
        
        let pageColors = Array(generatedColors[startIndex..<endIndex])
        return pageColors.enumerated().map { offset, color in
            SwatchDisplay(
                index: startIndex + offset,
                color: color,
                size: .medium,
                label: "\(startIndex + offset)"
            )
        }
    }
    
    /// Grouped swatches for grouped display
    var groupedSwatches: [[SwatchDisplay]] {
        var groups: [[SwatchDisplay]] = []
        
        for groupStart in stride(from: 0, to: totalColors, by: groupSize) {
            let groupEnd = min(groupStart + groupSize, totalColors)
            let groupColors = Array(generatedColors[groupStart..<groupEnd])
            
            let groupSwatches = groupColors.enumerated().map { offset, color in
                SwatchDisplay(
                    index: groupStart + offset,
                    color: color,
                    size: .small,
                    label: "\(groupStart + offset)"
                )
            }
            groups.append(groupSwatches)
        }
        
        return groups
    }
    
    // MARK: - Actions
    
    /// Generate palette
    func generatePalette() {
        guard canGenerate else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let config = ColorJourneyConfig.singleAnchor(defaultAnchor, style: .balanced)
        let journey = ColorJourney(config: config)
        
        generatedColors = journey.discrete(count: requestedCount)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let durationMs = (endTime - startTime) * 1000
        
        generationTiming = String(format: "%.2fms for %d colors (%.2fμs/color)", 
                                  durationMs, 
                                  requestedCount,
                                  durationMs * 1000 / Double(requestedCount))
        
        // Auto-select display mode based on count
        if requestedCount > RequestLimits.recommendedMaximum {
            displayMode = .paged
        } else if requestedCount > RequestLimits.warningThreshold {
            displayMode = .grouped
        } else {
            displayMode = .grid
        }
        
        currentPage = 0
        showResults = true
    }
    
    /// Navigate to previous page
    func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    /// Navigate to next page
    func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
}
