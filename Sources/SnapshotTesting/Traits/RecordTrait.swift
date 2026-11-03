// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

/// A trait that sets the record mode of a test or suite.
///
/// Create one with ``Testing/Trait/record(_:)``.
public struct RecordTrait: SuiteTrait, TestTrait {

    /// Applies the trait to the tests nested in a suite.
    public let isRecursive = true
    let recordMode: RecordMode
}

extension Trait where Self == RecordTrait {

    /// Sets the record mode of a test or suite.
    ///
    /// The record mode decides when snapshots are written. The default is `.missing`, which writes a
    /// snapshot only when there is no reference for it yet.
    ///
    /// ```swift
    /// @Test(.record(.all))
    /// func recordAllSnapshots() async throws {
    ///     // ...
    /// }
    ///
    /// @Suite(.record(.never))
    /// struct NoRecordingTests {
    ///     // ...
    /// }
    /// ```
    ///
    /// - Parameter recordMode: The record mode to use.
    /// - Returns: A trait to apply to a suite or a test.
    public static func record(_ recordMode: RecordMode) -> Self {
        .init(recordMode: recordMode)
    }
}
#endif
