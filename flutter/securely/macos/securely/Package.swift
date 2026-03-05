// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "securely",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "securely", targets: ["securely"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "securely",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
