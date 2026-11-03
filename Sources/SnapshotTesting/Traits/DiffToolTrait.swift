// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

/// A trait that sets the diff tool of a test or suite.
///
/// Create one with ``Testing/Trait/diffTool(_:)``.
public struct DiffToolTrait: SuiteTrait, TestTrait {

    /// Applies the trait to the tests nested in a suite.
    public let isRecursive = true
    let diffTool: DiffTool
}

extension Trait where Self == DiffToolTrait {

    /// Sets the diff tool used when a snapshot does not match its reference.
    ///
    /// The diff tool turns the paths of the reference and of the new output into the text shown in
    /// the failure message, usually a command that opens both in a visual diff application.
    ///
    /// - Parameter diffTool: The diff tool to use within the scope of the trait.
    /// - Returns: A trait to apply to a suite or a test.
    ///
    /// ```swift
    /// @Suite(.diffTool(.ksdiff))
    /// struct MySnapshotTests { ... }
    /// ```
    public static func diffTool(_ diffTool: DiffTool) -> Self {
        .init(diffTool: diffTool)
    }
}
#endif
