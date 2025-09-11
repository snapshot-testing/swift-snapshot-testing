// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-snapshot-testing",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "SnapshotTesting",
            targets: ["SnapshotTesting"]
        ),
        .library(
            name: "InlineSnapshotTesting",
            targets: ["InlineSnapshotTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/snapshot-testing/xc-snapshot-testing", from: "0.1.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "601.0.0"..<"602.0.0"),
    ],
    targets: [
        .target(
            name: "SnapshotTesting",
            dependencies: [
                .product(name: "XCSnapshotTesting", package: "xc-snapshot-testing"),
            ]
        ),
        .target(
            name: "InlineSnapshotTesting",
            dependencies: [
                "SnapshotTesting",
                .product(name: "XCSnapshotTestingCustomDump", package: "xc-snapshot-testing"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SnapshotTestingTests",
            dependencies: ["SnapshotTesting"],
            exclude: ["__Snapshots__"]
        ),
        .testTarget(
            name: "InlineSnapshotTestingTests",
            dependencies: ["InlineSnapshotTesting"]
        ),
    ]
)
