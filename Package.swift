// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TickerNormalizer",
    products: [
        .library(name: "TickerNormalizer", targets: ["TickerNormalizer"]),
    ],
    targets: [
        .target(name: "TickerNormalizer"),
        .testTarget(name: "TickerNormalizerTests", dependencies: ["TickerNormalizer"]),
    ]
)
