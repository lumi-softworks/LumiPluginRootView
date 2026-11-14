// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LumiPluginRootView",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PluginRootView",
            targets: ["PluginRootView"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.23.0"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.17.1")
    ],
    targets: [
        .target(
            name: "PluginRootView",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "ProviderActivityBar", package: "LumiProviders"),
                .product(name: "ProviderRailView", package: "LumiProviders"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "LumiUI", package: "LumiUI")
            ],
            path: "Sources/PluginRootView",
            resources: [.process("../../Resources/PluginRootView.xcstrings")]
        ),
        .testTarget(
            name: "PluginRootViewTests",
            dependencies: [
                "PluginRootView",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderActivityBar", package: "LumiProviders"),
                .product(name: "ProviderRailView", package: "LumiProviders"),
                .product(name: "ProviderRootView", package: "LumiProviders")
            ],
            path: "Tests/PluginRootViewTests"
        )
    ]
)
