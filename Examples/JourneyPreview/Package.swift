// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JourneyPreview",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    dependencies: [
        .package(name: "ColorJourney", path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "JourneyPreview",
            dependencies: ["ColorJourney"],
            path: ".",
            sources: [
                // Main app
                "ContentView.swift",
                "JourneyPreviewApp.swift",
                
                // Models
                "Models/ColorSetRequest.swift",
                "Models/SwatchDisplay.swift",
                "Models/CodeSnippet.swift",
                "Models/UserAdjustment.swift",
                "Models/InputValidation.swift",
                
                // ViewModels
                "ViewModels/PaletteExplorerViewModel.swift",
                "ViewModels/UsageExamplesViewModel.swift",
                "ViewModels/LargePaletteViewModel.swift",
                
                // Views
                "Views/PaletteExplorerView.swift",
                "Views/UsageExamplesView.swift",
                "Views/LargePaletteView.swift",
                
                // Shared Components
                "Views/Shared/SwatchGrid.swift",
                "Views/Shared/AdvisoryBox.swift",
                "Views/Shared/CodeSnippetView.swift"
            ],
            resources: [.copy("README.md")]
        )
    ]
)
