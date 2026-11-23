// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ArchipelagoSDK",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "SurfaceContracts", targets: ["SurfaceContracts"]),
        .library(name: "SurfaceSDK", targets: ["SurfaceSDK"]),
        .library(name: "ArchipelagoSDK", targets: ["SurfaceSDK", "SurfaceContracts"]),
    ],
    targets: [
        .target(
            name: "SurfaceContracts",
            path: "Sources/SurfaceContracts",
            resources: [
                .process("Fixtures")
            ]
        ),
        .target(
            name: "SurfaceSDK",
            dependencies: ["SurfaceContracts"],
            path: "Sources/SurfaceSDK"
        ),
    ]
)
