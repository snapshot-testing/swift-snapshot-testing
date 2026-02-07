[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsnapshot-testing%2Fswift-snapshot-testing%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/snapshot-testing/swift-snapshot-testing)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsnapshot-testing%2Fswift-snapshot-testing%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/snapshot-testing/swift-snapshot-testing)
[![codecov](https://codecov.io/gh/snapshot-testing/swift-snapshot-testing/graph/badge.svg?token=YN43HSRRAU)](https://codecov.io/gh/snapshot-testing/swift-snapshot-testing)


# SnapshotTesting

A Swift library that provides Traits and methods for implementing snapshot testing with Swift's new `Testing` framework. This library enables developers to capture and verify the state of their views, data structures, and more by comparing them against previously recorded "snapshots" using Swift's modern testing infrastructure.

## Features

- **Swift Testing Framework Integration**: Built specifically for Swift's `Testing` framework
- **Traits Implementation**: Provides Traits for snapshot testing capabilities
- **Multiple Output Formats**: Support for image snapshots, string diffs, JSON, and more
- **Flexible Configuration**: Customize precision, naming, and comparison strategies
- **SwiftUI Support**: First-class support for testing SwiftUI views
- **UIKit Support**: Comprehensive testing for UIKit components
- **Cross-Platform**: Works across iOS, macOS, tvOS, and watchOS
- **Performance Optimized**: Efficient snapshot comparison algorithms
- **Developer Friendly**: Clear error messages and debugging tools

## Installation

SnapshotTesting can be installed using Swift Package Manager. To include it in your project, add the following dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/snapshot-testing/swift-snapshot-testing", from: "1.0.0")
]
```

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

### Available Traits

The library provides various Traits for different snapshot testing needs:

- `SnapshotTestingTrait` - Main trait for snapshot testing capabilities
- `ImageSnapshotTrait` - For capturing image-based snapshots
- `StringSnapshotTrait` - For capturing string-based snapshots
- `JSONSnapshotTrait` - For capturing JSON-based snapshots

### Common Snapshot Strategies

SnapshotTesting provides various strategies for different types of content:

- `.image` - Captures a view or view controller as an image
- `.string` - Captures content as a string
- `.json` - Captures encodable data as JSON
- `.recursiveDescription` - Captures the recursive description of a view

For more examples and advanced usage, please refer to our documentation.

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
