import SwiftUI
import ColorJourney

/// Main content view with tabbed navigation between demo pages.
struct ContentView: View {
    @State private var selectedTab: DemoTab = .paletteExplorer
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .frame(minWidth: 900, minHeight: 700)
    }
    
    // MARK: - Sidebar
    
    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            Section("Explore") {
                NavigationLink(value: DemoTab.paletteExplorer) {
                    Label("Palette Explorer", systemImage: "paintpalette.fill")
                }
                
                NavigationLink(value: DemoTab.usageExamples) {
                    Label("Usage Examples", systemImage: "doc.text.fill")
                }
                
                NavigationLink(value: DemoTab.largePalettes) {
                    Label("Large Palettes", systemImage: "square.grid.3x3.fill")
                }
            }
            
            Section("About") {
                NavigationLink(value: DemoTab.about) {
                    Label("About ColorJourney", systemImage: "info.circle.fill")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("JourneyPreview")
    }
    
    // MARK: - Detail Content
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .paletteExplorer:
            PaletteExplorerView()
        case .usageExamples:
            UsageExamplesView()
        case .largePalettes:
            LargePaletteView()
        case .about:
            AboutView()
        }
    }
}

// MARK: - Demo Tabs

enum DemoTab: String, CaseIterable, Identifiable {
    case paletteExplorer = "palette_explorer"
    case usageExamples = "usage_examples"
    case largePalettes = "large_palettes"
    case about = "about"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .paletteExplorer: return "Palette Explorer"
        case .usageExamples: return "Usage Examples"
        case .largePalettes: return "Large Palettes"
        case .about: return "About"
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("ColorJourney")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Perceptually Uniform Color Palette Generator")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Features
                VStack(alignment: .leading, spacing: 24) {
                    featureRow(
                        icon: "waveform.path",
                        title: "Perceptual Uniformity",
                        description: "Colors are spaced using OKLab perceptual distance, ensuring consistent visual differences."
                    )
                    
                    featureRow(
                        icon: "bolt.fill",
                        title: "High Performance",
                        description: "Generate millions of colors per second. ~0.6μs per color on modern hardware."
                    )
                    
                    featureRow(
                        icon: "arrow.triangle.branch",
                        title: "Deterministic Output",
                        description: "Same configuration always produces identical results. Perfect for reproducible designs."
                    )
                    
                    featureRow(
                        icon: "c.square.fill",
                        title: "C-First Architecture",
                        description: "High-performance C99 core with Swift, Python, and other language bindings."
                    )
                }
                .padding(.horizontal, 40)
                
                // Links
                VStack(spacing: 12) {
                    Link("GitHub Repository", destination: URL(string: "https://github.com/peternicholls/ColorJourney")!)
                        .buttonStyle(.bordered)
                    
                    Link("Documentation", destination: URL(string: "https://github.com/peternicholls/ColorJourney#readme")!)
                        .buttonStyle(.bordered)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(white: 0.1))
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Legacy Support

/// Legacy journey swatch view (kept for reference)
struct LegacyJourneySwatchView: View {
    let title: String
    let colors: [ColorJourneyRGB]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Discrete Swatches")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Individually generated colors from the journey.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Swatches grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: min(10, colors.count))
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(
                            red: Double(color.red),
                            green: Double(color.green),
                            blue: Double(color.blue)
                        ))
                        .frame(height: 110)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.15))
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        )
    }
}

// Helper function to generate a journey (legacy support)
func generateJourney(anchor: ColorJourneyRGB, style: JourneyStyle, count: Int) -> [ColorJourneyRGB] {
    let config = ColorJourneyConfig.singleAnchor(anchor, style: style)
    let journey = ColorJourney(config: config)
    return journey.discrete(count: count)
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
