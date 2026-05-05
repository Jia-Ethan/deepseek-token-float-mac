// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeepSeekTokenFloatMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DeepSeekTokenFloatMac",
            targets: ["DeepSeekTokenFloatMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DeepSeekTokenFloatMac",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Security"),
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
