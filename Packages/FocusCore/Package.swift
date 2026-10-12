// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FocusCore",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "FocusCore", targets: ["FocusCore"])
    ],
    targets: [
        .target(name: "FocusCore"),
        .testTarget(name: "FocusCoreTests", dependencies: ["FocusCore"]),
    ]
)
