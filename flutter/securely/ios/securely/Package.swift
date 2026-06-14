// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "securely",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15")
    ],
    products: [
        .library(name: "securely", targets: ["securely"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "securely",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],

            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
