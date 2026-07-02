// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationModelsBench",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "FoundationModelsBenchCore",
            targets: ["FoundationModelsBenchCore"]
        ),
        .executable(
            name: "foundation-models-bench",
            targets: ["FoundationModelsBenchCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/rryam/FoundationModelsKit", branch: "main")
    ],
    targets: [
        .target(
            name: "FoundationModelsBenchCore",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ]
        ),
        .executableTarget(
            name: "FoundationModelsBenchCLI",
            dependencies: ["FoundationModelsBenchCore"]
        ),
        .testTarget(
            name: "FoundationModelsBenchCoreTests",
            dependencies: ["FoundationModelsBenchCore"]
        )
    ]
)
