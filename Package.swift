// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PeekPairs",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "PeekPairsCore", targets: ["PeekPairsCore"]),
        .executable(name: "PeekPairs", targets: ["PeekPairsApp"])
    ],
    targets: [
        .target(
            name: "PeekPairsCore"
        ),
        .executableTarget(
            name: "PeekPairsApp",
            dependencies: ["PeekPairsCore"],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
        .testTarget(
            name: "PeekPairsCoreTests",
            dependencies: ["PeekPairsCore"]
        )
    ]
)
