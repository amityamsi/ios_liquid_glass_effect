// swift-tools-version: 5.9
import PackageDescription

// Build through a Flutter iOS application using Xcode 26 or newer. Flutter
// supplies the adjacent FlutterFramework package during SwiftPM integration.
let package = Package(
    name: "ios_liquid_glass_effect",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "ios-liquid-glass-effect", targets: ["ios_liquid_glass_effect"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ios_liquid_glass_effect",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
