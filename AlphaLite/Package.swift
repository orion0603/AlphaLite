// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AlphaLite",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AlphaLite",
            targets: ["AlphaLite"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.4")
    ],
    targets: [
        .target(
            name: "AlphaLite",
            dependencies: ["OpenAI"]),
        .testTarget(
            name: "AlphaLiteTests",
            dependencies: ["AlphaLite"]),
    ]
) 