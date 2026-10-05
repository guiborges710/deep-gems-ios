// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepGemsCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "DeepGemsCore", targets: ["DeepGemsCore"]),
        .executable(name: "DeepGemsWebPreview", targets: ["DeepGemsWebPreview"])
    ],
    dependencies: [
        .package(url: "https://github.com/guiborges710/SwiftUIWeb.git", exact: "0.1.0")
    ],
    targets: [
        .target(name: "DeepGemsCore", path: "DeepGems/Core"),
        .target(name: "DeepGemsWebUI", dependencies: ["DeepGemsCore", .product(name: "SwiftUIWeb", package: "SwiftUIWeb")], path: "Web/DeepGemsWebUI"),
        .executableTarget(name: "DeepGemsWebPreview", dependencies: ["DeepGemsWebUI", "DeepGemsCore"], path: "Web/DeepGemsWebPreview"),
        .testTarget(name: "DeepGemsWebTests", dependencies: ["DeepGemsWebUI", "DeepGemsCore"], path: "Tests/DeepGemsWebTests"),
        .testTarget(name: "DeepGemsCoreTests", dependencies: ["DeepGemsCore"], path: "Tests/DeepGemsCoreTests")
    ]
)
