[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsnapshot-testing%2Fswift-snapshot-testing%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/snapshot-testing/swift-snapshot-testing)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsnapshot-testing%2Fswift-snapshot-testing%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/snapshot-testing/swift-snapshot-testing)
[![codecov](https://codecov.io/gh/snapshot-testing/swift-snapshot-testing/graph/badge.svg?token=YN43HSRRAU)](https://codecov.io/gh/snapshot-testing/swift-snapshot-testing)


# SnapshotTesting

A Swift library that provides Traits and methods for implementing snapshot testing with Swift's new `Testing` framework. This library enables developers to capture and verify the state of their views, data structures, and more by comparing them against previously recorded "snapshots" using Swift's modern testing infrastructure.

## Features

- **Swift Testing integration**: traits to configure a test or a whole suite, and failures reported through `Issue.record`
- **XCTest support**: the same assertions work in an `XCTestCase`
- **Multiple output formats**: images, text lines, JSON, property lists, custom dumps and more
- **Inline snapshots**: `assertInline` writes the expected value into the test file
- **SwiftUI and UIKit/AppKit**: snapshot views and view controllers
- **Cross-platform**: iOS, macOS, tvOS and watchOS

## Installation

SnapshotTesting can be installed using Swift Package Manager. To include it in your project, add the following dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/snapshot-testing/swift-snapshot-testing", from: "2.0.0")
]
```

The package has two products: `SnapshotTesting` and `InlineSnapshotTesting`.

## Usage

Getting started with SnapshotTesting is simple. Here's a basic example using Swift's `Testing` framework:

```swift
import Testing
import SnapshotTesting

@Test
func testMyView() async throws {
    let view = MyView()

    try await assert(of: view, as: .image)
}
```

### Traits

Traits configure the assertions of a test or of a whole suite. They apply recursively, and the closest one wins:

- `.record(_:)` - when references are written: `.missing` (the default), `.failed`, `.all` or `.never`
- `.diffTool(_:)` - the command printed in a failure to open a diff, such as `.ksdiff`
- `.maxConcurrentTests(_:)` - how many snapshots may use a window at the same time
- `.platform(_:)` - a platform name added to the reference path
- `.finalizeSnapshots` - on a suite, writes its inline snapshots when the suite ends (required by `assertInline` under Swift Testing)

```swift
@Suite(.record(.failed), .diffTool(.ksdiff))
struct FeatureTests { … }
```

### Common snapshot strategies

- `.image` - a view or view controller as an image
- `.lines` - text, compared line by line
- `.json` - an encodable value as JSON
- `.customDump` - a value as the text of `swift-custom-dump` (available with `InlineSnapshotTesting`)
- `.recursiveDescription` - the recursive description of a view

### Inline snapshots

```swift
import InlineSnapshotTesting

@Suite(.finalizeSnapshots)
struct InlineTests {

    @Test
    func greets() throws {
        try assertInline(of: ["Hello", "World"], as: .customDump) {
            """
            [
              [0]: "Hello",
              [1]: "World"
            ]
            """
        }
    }
}
```

For more examples and advanced usage, please refer to the documentation.

## Versioning

We follow semantic versioning for this project. The version number is composed of three parts: MAJOR.MINOR.PATCH.

- MAJOR version: Increments when there are incompatible changes and breaking changes. These changes may require updates to existing code and could potentially break backward compatibility.

- MINOR version: Increments when new features or enhancements are added in a backward-compatible manner. It may include improvements, additions, or modifications to existing functionality.

- The PATCH version includes bug fixes, patches, and safe modifications that address issues, bugs, or vulnerabilities without disrupting existing functionality. It may also include new features, but they must be implemented carefully to avoid breaking changes or compatibility issues.

It is recommended to review the release notes for each version to understand the specific changes and updates made in that particular release.

## Contributing

If you find a bug or have an idea for a new feature, please open an issue or  submit a pull request. We welcome contributions from the community!

## License

This library is released under the MIT License. See the [LICENSE](./LICENSE) file for more information.
