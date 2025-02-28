// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WDSP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WDSP",
            targets: ["WDSP"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WDSP",
            path: "WDSP",
            exclude: [
                ".DS_Store",
                "WDSP.entitlements",
                "WDSPAudioEngine.swift",
                "WDSPViews.swift",
            ],
            sources: [
                "main.swift",
                "WDSPApp.swift",
                "ContentView.swift",
                "AudioUnitViewModel.swift",
                "AudioUnitHostModel.swift",
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("readme.md"),
            ]
        )
    ]
)
