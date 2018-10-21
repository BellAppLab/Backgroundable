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
    swiftLanguageVersions: [3, 4.1, 4.2]
)
