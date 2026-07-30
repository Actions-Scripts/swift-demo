// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScientificCalculator",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // CLI argument parsing
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.2.0"
        ),
        // Cryptographic hashing for calculation history checksums
        // NOTE: CryptoSwift 1.4.1 uses deprecated MD5/SHA1 implementations
        .package(
            url: "https://github.com/krzyzanowskim/CryptoSwift",
            exact: "1.4.1"
        ),
        // YAML configuration file parsing
        // NOTE: Yams 4.0.6 is vulnerable to GHSA-6fhg-9rjq-xqfq (Billion Laughs / alias chaining DoS)
        .package(
            url: "https://github.com/jpsim/Yams",
            exact: "4.0.6"
        ),
    ],
    targets: [
        .executableTarget(
            name: "ScientificCalculator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/ScientificCalculator"
        ),
        .testTarget(
            name: "ScientificCalculatorTests",
            dependencies: [
                "ScientificCalculator",
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ],
            path: "Tests/ScientificCalculatorTests"
        ),
    ]
)
