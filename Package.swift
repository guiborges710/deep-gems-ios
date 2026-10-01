// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepGemsCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "DeepGemsCore", targets: ["DeepGemsCore"])],
    targets: [
        .target(name: "DeepGemsCore", path: "DeepGems/Core"),
        .testTarget(name: "DeepGemsCoreTests", dependencies: ["DeepGemsCore"], path: "Tests/DeepGemsCoreTests")
    ]
)
