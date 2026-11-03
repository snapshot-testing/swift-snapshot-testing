// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

/// A trait that sets the platform name used in the path of the reference snapshots.
///
/// Create one with ``Testing/Trait/platform(_:)``.
public struct PlatformTrait: SuiteTrait, TestTrait {

    /// Applies the trait to the tests nested in a suite.
    public let isRecursive = true
    let platform: String
}

extension Trait where Self == PlatformTrait {

    /// Sets the platform name used in the path of the reference snapshots.
    ///
    /// References are stored in a directory named after the platform, such as `__Snapshots__/iOS`.
    /// By default the name is that of the platform running the test. Set it to read references
    /// that were recorded on another platform.
    ///
    /// ```swift
    /// @Suite(.platform("iOS"))
    /// struct MySnapshotTests { ... }
    /// ```
    ///
    /// - Parameter platform: The platform name. `nil` or an empty string removes the platform
    ///   directory, so every platform shares the same references.
    /// - Returns: A trait to apply to a suite or a test.
    public static func platform(_ platform: String?) -> Self {
        .init(platform: platform ?? "")
    }
}
#endif
