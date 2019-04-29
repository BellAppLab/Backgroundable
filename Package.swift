// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "Backgroundable",
    products: [
        .library(name: "Backgroundable",
                 targets: ["Backgroundable"]),
        ],
    targets: [
        .target(
            name: "Backgroundable"
        ),
        .testTarget(
            name: "BackgroundableTests",
            dependencies: ["Backgroundable"]),
        ],
    swiftLanguageVersions: [4.2, 5.0]
)
