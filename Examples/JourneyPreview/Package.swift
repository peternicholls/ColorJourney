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
            sources: ["ContentView.swift", "JourneyPreviewApp.swift"],
            resources: [.copy("README.md")]
        )
    ]
)
