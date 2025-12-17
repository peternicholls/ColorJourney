// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftParityRunner",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "swift-parity-runner",
            targets: ["SwiftParityRunner"]
        )
    ],
    dependencies: [
        .package(path: "../../../..")
    ],
    targets: [
        .executableTarget(
            name: "SwiftParityRunner",
            dependencies: [
                .product(name: "ColorJourney", package: "colourjourney")
            ]
        ),
        .testTarget(
            name: "SwiftParityRunnerTests",
            dependencies: ["SwiftParityRunner"],
            resources: []
        )
    ]
)
