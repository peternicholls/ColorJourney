// swift-tools-version: 5.9
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
            publicHeadersPath: "include",
            cSettings: [
                .define("_GNU_SOURCE"),
                .unsafeFlags(["-O3", "-ffast-math"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "ColorJourney",
            dependencies: ["CColorJourney"]
        ),
        .testTarget(
            name: "ColorJourneyTests",
            dependencies: ["ColorJourney"]
        )
    ]
)
