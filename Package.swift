// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-snapshot-testing",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v9),
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
        .package(path: "../xc-snapshot-testing"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "603.0.0"..<"605.0.0"),
    ],
    targets: [
        .target(
            name: "SnapshotTesting",
            dependencies: [
                .product(name: "XCSnapshotTesting", package: "xc-snapshot-testing")
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
