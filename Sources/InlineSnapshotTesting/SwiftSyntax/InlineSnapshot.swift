// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(SwiftSyntax601)
import SwiftSyntax
import Foundation

/// An inline snapshot captured during a test, waiting to be written into the test source.
///
/// The inline engine keeps one for each assertion. When the run ends, the source of the test is
/// rewritten so that every snapshot that was recorded, and that differs from its reference, ends
/// up in the trailing closure of its assertion.
public struct InlineSnapshot: Sendable, Hashable {

    /// The snapshot previously stored for the same location during the run, or `nil` if there was none.
    public let reference: Data?

    /// The serialized output of the assertion.
    public let diffable: Data

    /// Whether the assertion recorded ``diffable`` as the new snapshot, rather than only comparing it.
    public let wasRecording: Bool

    /// Describes the trailing closure that holds the snapshot.
    public let closureDescriptor: SnapshotClosureDescriptor

    /// The name of the test function that made the assertion.
    public let function: String

    /// The line of the assertion.
    public let line: UInt

    /// The column of the assertion.
    public let column: UInt

    /// Creates an inline snapshot.
    ///
    /// - Parameters:
    ///   - reference: The snapshot previously stored for the same location, if any.
    ///   - diffable: The serialized output of the assertion.
    ///   - wasRecording: Whether the assertion recorded `diffable` as the new snapshot.
    ///   - closureDescriptor: Describes the trailing closure that holds the snapshot.
    ///   - function: The name of the test function that made the assertion.
    ///   - line: The line of the assertion.
    ///   - column: The column of the assertion.
    public init(
        reference: Data?,
        diffable: Data,
        wasRecording: Bool,
        closureDescriptor: SnapshotClosureDescriptor,
        function: String,
        line: UInt,
        column: UInt
    ) {
        self.reference = reference
        self.diffable = diffable
        self.wasRecording = wasRecording
        self.closureDescriptor = closureDescriptor
        self.function = function
        self.line = line
        self.column = column
    }
}
#endif
