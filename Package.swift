// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ColourJourney",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ColourJourney",
            targets: ["ColourJourney"]
        )
    ],
    targets: [
        .target(
            name: "CColourJourney",
            path: "Sources/CColourJourney",
            sources: ["colour_journey.c"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "ColourJourney",
            dependencies: ["CColourJourney"],
            path: "Sources/ColourJourney"
        )
    ]
)
