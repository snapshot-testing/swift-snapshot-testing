// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

@_spi(Internals) import XCSnapshotTesting

/// Describes the trailing closure that holds an inline snapshot.
///
/// Pass one to ``assertInline(of:as:message:record:timeout:name:serialization:closureDescriptor:matches:fileID:file:function:line:column:)``
/// from a custom assertion whose snapshot closure is not the first trailing closure, or is not
/// labeled `matches`. The library uses it to find that closure in the source of the test, both to
/// write the snapshot into it and to report a failure on its line.
///
/// A label that was renamed can be listed in ``deprecatedTrailingClosureLabels``, so call sites
/// that still use the old label are found as well.
public struct SnapshotClosureDescriptor: Sendable, Hashable {

    /// The default label describing an inline snapshot.
    public static let defaultTrailingClosureLabel = "matches"

    /// Labels that earlier versions of the helper used for the snapshot closure.
    public var deprecatedTrailingClosureLabels: [String]

    /// The label of the trailing closure that returns the inline snapshot.
    public var trailingClosureLabel: String

    /// The offset of the trailing closure that returns the inline snapshot, relative to the first
    /// trailing closure.
    ///
    /// For example, a helper function with a few parameters and a single trailing closure has a
    /// trailing closure offset of 0:
    ///
    /// ```swift
    /// customInlineSnapshot(of: value, "Should match") {
    ///   // Inline snapshot...
    /// }
    /// ```
    ///
    /// While a helper function with a trailing closure preceding the snapshot closure has an offset
    /// of 1:
    ///
    /// ```swift
    /// customInlineSnapshot("Should match") {
    ///   // Some other parameter...
    /// } matches: {
    ///   // Inline snapshot...
    /// }
    /// ```
    public var trailingClosureOffset: Int

    /// Initializes an inline snapshot syntax descriptor.
    ///
    /// - Parameters:
    ///   - deprecatedTrailingClosureLabels: An array of deprecated labels to consider for the inline
    ///     snapshot.
    ///   - trailingClosureLabel: The label of the trailing closure that returns the inline snapshot.
    ///   - trailingClosureOffset: The offset of the trailing closure that returns the inline
    ///     snapshot, relative to the first trailing closure.
    public init(
        deprecatedTrailingClosureLabels: [String] = [],
        trailingClosureLabel: String = Self.defaultTrailingClosureLabel,
        trailingClosureOffset: Int = 0
    ) {
        self.deprecatedTrailingClosureLabels = deprecatedTrailingClosureLabels
        self.trailingClosureLabel = trailingClosureLabel
        self.trailingClosureOffset = trailingClosureOffset
    }

    #if canImport(SwiftSyntax601)
    /// Generates a test failure immediately and unconditionally at the described trailing closure.
    ///
    /// This method tries to locate the line of the trailing closure described by this type and
    /// reports the failure there. If the trailing closure cannot be located, the failure is
    /// reported on the given line instead.
    ///
    /// - Parameters:
    ///   - message: An optional description of the assertion, for inclusion in test results.
    ///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case
    ///     in which this function was called.
    ///   - filePath: The file in which failure occurred. Defaults to the file path of the test case in
    ///     which this function was called.
    ///   - line: The line number on which failure occurred. Defaults to the line number on which
    ///     this function was called.
    ///   - column: The column on which failure occurred. Defaults to the column on which this
    ///     function was called.
    /// - Throws: The failure itself, when neither XCTest nor Swift Testing is available to record it.
    public func fail(
        _ message: @autoclosure () -> String,
        fileID: StaticString,
        file filePath: StaticString,
        line: UInt,
        column: UInt
    ) throws {
        var trailingClosureLine: Int?
        if let testSource = InlineSnapshotManager.current[SnapshotURL(path: filePath)] {
            let visitor = SnapshotVisitor(
                functionCallLine: Int(line),
                functionCallColumn: Int(column),
                sourceLocationConverter: testSource.sourceLocationConverter,
                closureDescriptor: self
            )
            visitor.walk(testSource.sourceFile)
            trailingClosureLine = visitor.trailingClosureLine
        }

        try TestingSystem.shared.record(
            message: message(),
            fileID: fileID,
            filePath: filePath,
            line: trailingClosureLine.map(UInt.init) ?? line,
            column: column
        )
    }

    func contains(_ label: String) -> Bool {
        self.trailingClosureLabel == label || self.deprecatedTrailingClosureLabels.contains(label)
    }
    #else
    /// Unavailable: reporting at the closure needs `SwiftSyntax601` to be importable.
    @available(*, unavailable, message: "'assertInline' requires 'swift-syntax' >= 509.0.0")
    public func fail(
        _ message: @autoclosure () -> String = "",
        fileID: StaticString,
        file filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        fatalError()
    }
    #endif
}
