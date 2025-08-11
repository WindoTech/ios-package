// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "beacon",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "beacon",
            targets: ["BeaconBar"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BeaconBar",
            dependencies: [],
            path: "Sources/BeaconBar",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "BeaconBarTests",
            dependencies: ["BeaconBar"],
            path: "Tests/BeaconBarTests"
        ),
    ]
)
