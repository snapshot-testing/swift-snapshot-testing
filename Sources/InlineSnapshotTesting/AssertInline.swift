// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
@_spi(Internals) import XCSnapshotTesting

#if canImport(SwiftSyntax601)
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// Asserts that a value matches the snapshot written in the trailing closure of the call.
///
/// The value goes through `snapshot`, and the output is compared with the string in the closure. If
/// the closure is missing, the output is written into the test source and the test fails, so you
/// can review it. The record mode decides whether it is written. Run the test again to compare
/// against it.
///
/// ```swift
/// try await assertInline(of: user, as: .json) {
///     """
///     {
///       "id" : 42,
///       "name" : "Blob"
///     }
///     """
/// }
/// ```
///
/// - Parameters:
///   - value: The value to snapshot. It is evaluated when the assertion runs.
///   - snapshot: How to turn the value into the output that is compared.
///   - message: A description to show when the output does not match.
///   - record: Overrides the record mode of the environment for this assertion.
///   - timeout: How long to wait for the snapshot, in seconds. The default is 5.
///   - name: A name that tells this snapshot apart from the others in the same test.
///   - serialization: How the output is encoded and decoded.
///   - closureDescriptor: Describes the closure that holds the snapshot. Only custom helpers need to change it.
///   - expected: The snapshot to compare with. The trailing closure of the call provides it.
///   - isolation: The actor that evaluates `value`.
///   - fileID: The `#fileID` of the call.
///   - filePath: The `#filePath` of the call.
///   - function: The name of the test function.
///   - line: The line of the call.
///   - column: The column of the call.
/// - Throws: An error from evaluating `value`, running the snapshot, or writing the result.
///
/// - Important: With Swift Testing, apply `@Suite(.finalizeSnapshots)` to the suite. Without it, the call stops with a precondition failure.
///
/// - SeeAlso: <doc:InlineSnapshotTesting>
public func assertInline<Input: Sendable, Output: BytesRepresentable>(
    of value: @autoclosure @Sendable () async throws -> Input,
    as snapshot: AsyncSnapshot<Input, Output>,
    message: @autoclosure @escaping @Sendable () -> String = "",
    record: RecordMode? = nil,
    timeout: TimeInterval = 5,
    name: String? = nil,
    serialization: DataSerialization = DataSerialization(),
    closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
    matches expected: (@Sendable () -> Output.RawValue)? = nil,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    let engine = try SnapshotInlineEngine<XCSnapshotTesting.Async<Input, Output>>(
        expected: expected,
        message: message,
        closureDescriptor: closureDescriptor,
        line: line,
        column: column
    )

    let tester = SnapshotTester(
        engine: engine,
        record: record,
        timeout: timeout,
        name: name,
        serialization: serialization,
        fileID: fileID,
        filePath: filePath,
        function: function,
        line: line,
        column: column
    )

    guard let failure = try await tester(value(), for: snapshot) else {
        return
    }

    switch failure.reason {
    case .doesNotMatch:
        try closureDescriptor.fail(
            failure.message,
            fileID: fileID,
            file: filePath,
            line: line,
            column: column
        )
    default:
        try TestingSystem.shared.record(
            message: failure.message,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

/// Asserts that a value matches the snapshot written in the trailing closure of the call.
///
/// The value goes through `snapshot`, and the output is compared with the string in the closure. If
/// the closure is missing, the output is written into the test source and the test fails, so you
/// can review it. The record mode decides whether it is written. Run the test again to compare
/// against it.
///
/// ```swift
/// try assertInline(of: user, as: .json) {
///     """
///     {
///       "id" : 42,
///       "name" : "Blob"
///     }
///     """
/// }
/// ```
///
/// - Parameters:
///   - value: The value to snapshot. It is evaluated when the assertion runs.
///   - snapshot: How to turn the value into the output that is compared.
///   - message: A description to show when the output does not match.
///   - record: Overrides the record mode of the environment for this assertion.
///   - timeout: How long to wait for the snapshot, in seconds. The default is 5.
///   - name: A name that tells this snapshot apart from the others in the same test.
///   - serialization: How the output is encoded and decoded.
///   - closureDescriptor: Describes the closure that holds the snapshot. Only custom helpers need to change it.
///   - expected: The snapshot to compare with. The trailing closure of the call provides it.
///   - fileID: The `#fileID` of the call.
///   - filePath: The `#filePath` of the call.
///   - function: The name of the test function.
///   - line: The line of the call.
///   - column: The column of the call.
/// - Throws: An error from evaluating `value`, running the snapshot, or writing the result.
///
/// - Important: With Swift Testing, apply `@Suite(.finalizeSnapshots)` to the suite. Without it, the call stops with a precondition failure.
///
/// - SeeAlso: <doc:InlineSnapshotTesting>
public func assertInline<Input, Output: BytesRepresentable>(
    of value: @autoclosure @Sendable () throws -> Input,
    as snapshot: SyncSnapshot<Input, Output>,
    message: @autoclosure @escaping @Sendable () -> String = "",
    record: RecordMode? = nil,
    timeout: TimeInterval = 5,
    name: String? = nil,
    serialization: DataSerialization = DataSerialization(),
    closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
    matches expected: (@Sendable () -> Output.RawValue)? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) throws {
    let engine = try SnapshotInlineEngine<Sync<Input, Output>>(
        expected: expected,
        message: message,
        closureDescriptor: closureDescriptor,
        line: line,
        column: column
    )

    let tester = SnapshotTester(
        engine: engine,
        record: record,
        timeout: timeout,
        name: name,
        serialization: serialization,
        fileID: fileID,
        filePath: filePath,
        function: function,
        line: line,
        column: column
    )

    guard let failure = try tester(value(), for: snapshot) else {
        return
    }

    switch failure.reason {
    case .doesNotMatch:
        try closureDescriptor.fail(
            failure.message,
            fileID: fileID,
            file: filePath,
            line: line,
            column: column
        )
    default:
        try TestingSystem.shared.record(
            message: failure.message,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}
#else
/// Unavailable: `assertInline` needs `swift-syntax` 601.0.0 or later.
@available(*, unavailable, message: "'assertInline' requires 'swift-syntax' >= 601.0.0")
public func assertInline<Input: Sendable, Output: BytesRepresentable>(
    of value: @autoclosure @Sendable () async throws -> Input,
    as snapshot: AsyncSnapshot<Input, Output>,
    message: @autoclosure @escaping @Sendable () -> String = "",
    record: RecordMode? = nil,
    timeout: TimeInterval = 5,
    name: String? = nil,
    serialization: DataSerialization = DataSerialization(),
    closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
    matches expected: (@Sendable () -> Output.RawValue)? = nil,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    fatalError()
}

/// Unavailable: `assertInline` needs `swift-syntax` 601.0.0 or later.
@available(*, unavailable, message: "'assertInline' requires 'swift-syntax' >= 601.0.0")
public func assertInline<Input, Output: BytesRepresentable>(
    of value: @autoclosure @Sendable () throws -> Input,
    as snapshot: SyncSnapshot<Input, Output>,
    message: @autoclosure @escaping @Sendable () -> String = "",
    record: RecordMode? = nil,
    timeout: TimeInterval = 5,
    name: String? = nil,
    serialization: DataSerialization = DataSerialization(),
    closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
    matches expected: (@Sendable () -> Output.RawValue)? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) throws {
    fatalError()
}
#endif
