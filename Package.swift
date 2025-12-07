// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColourJourney",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
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
            publicHeadersPath: "include",
            cSettings: [
                .define("_GNU_SOURCE"),
                .unsafeFlags(["-O3", "-ffast-math"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "ColourJourney",
            dependencies: ["CColourJourney"],
            path: "Sources/ColourJourney",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "ColourJourneyTests",
            dependencies: ["ColourJourney"]
        )
    ]
)