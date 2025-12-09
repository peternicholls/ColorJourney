// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColorJourney",
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
            name: "ColorJourney",
            targets: ["ColorJourney"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CColorJourney",
            path: "Sources/CColorJourney",
            sources: ["ColorJourney.c"],
            publicHeadersPath: "include",
            cSettings: [
                .define("_GNU_SOURCE"),
                .unsafeFlags(["-O3", "-ffast-math"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "ColorJourney",
            dependencies: ["CColorJourney"],
            path: "Sources/ColorJourney",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "ColorJourneyTests",
            dependencies: ["ColorJourney"]
        )
    ]
)
