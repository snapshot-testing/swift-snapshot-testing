// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

/// A trait that sets how many windows UI snapshots can use at the same time.
///
/// Create one with ``Testing/Trait/maxConcurrentTests(_:)``.
public struct MaxConcurrentTestsTrait: SuiteTrait, TestTrait {

    /// Applies the trait to the tests nested in a suite.
    public let isRecursive = true
    let maxConcurrentTests: Int
}

extension Trait where Self == MaxConcurrentTestsTrait {

    /// Sets how many windows UI snapshots can use at the same time.
    ///
    /// Rendering a UI snapshot takes a `UIWindow` (`NSWindow` on macOS) from a pool. The limit is the
    /// size of that pool, so a snapshot waits for a window when all of them are in use. A low limit
    /// keeps the device from being overloaded when many snapshot tests run in parallel. The default is 3.
    ///
    /// This does not limit how many tests run in parallel, only how many of them render at once.
    ///
    /// - Parameter maxConcurrentTests: The maximum number of windows. Values lower than one are treated as one.
    /// - Returns: A trait to apply to a suite or a test.
    ///
    /// ```swift
    /// @Suite(.maxConcurrentTests(2))
    /// struct MySuite { ... }
    /// ```
    public static func maxConcurrentTests(_ maxConcurrentTests: Int) -> Self {
        .init(maxConcurrentTests: max(1, maxConcurrentTests))
    }
}
#endif
