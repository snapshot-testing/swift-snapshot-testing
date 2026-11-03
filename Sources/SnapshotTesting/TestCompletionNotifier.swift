// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

/// A suite trait that tells the library when every test of the suite has finished.
///
/// Create one with ``Testing/Trait/finalizeSnapshots``.
public struct FinalizeSnapshotsSuiteTrait: SuiteTrait {

    /// The trait applies only to the suite that declares it, not to the suites nested in it.
    public let isRecursive = false

    /// Returns the scope that tracks the completion of the suite.
    public func scopeProvider(
        for test: Test,
        testCase: Test.Case?
    ) -> TestScopeProvider? {
        TestScopeProvider()
    }
}

extension Trait where Self == FinalizeSnapshotsSuiteTrait {

    /// Writes the pending inline snapshots into the test file once the suite has finished.
    ///
    /// Inline snapshots are written into the source of the test once its tests have run. XCTest
    /// reports the end of the test bundle, and that is when the library writes them. Under Swift
    /// Testing this trait provides that signal, and `assertInline` stops with a precondition failure
    /// if the suite does not apply it.
    ///
    /// ```swift
    /// @Suite(.finalizeSnapshots)
    /// struct MySnapshotTests { ... }
    /// ```
    ///
    /// The trait applies only to the suite that declares it, not to the suites nested in it.
    public static var finalizeSnapshots: Self {
        .init()
    }
}

extension FinalizeSnapshotsSuiteTrait {

    /// The scope that keeps track of the suite until its tests have finished.
    public struct TestScopeProvider: TestScoping {

        /// Runs `function`, and notifies the library when the suite has finished.
        public func provideScope(
            for test: Test,
            testCase: Test.Case?,
            performing function: @Sendable () async throws -> Void
        ) async throws {
            try await withTestCompletionTracking(
                for: test,
                operation: function
            )
        }
    }
}

private nonisolated(nonsending) func withTestCompletionTracking<R: Sendable>(
    for test: Test,
    operation: nonisolated(nonsending) () async throws -> R,
    file: String = #file,
    line: UInt = #line
) async throws -> R {
    precondition(test.isSuite)

    if TestCompletionNotifier.current != nil {
        return try await operation()
    }

    let notifier = TestCompletionNotifier(test.sourceLocation)

    // The notification is posted when the scope ends, not when the last reference to the notifier
    // goes away: tasks that inherit the task-local would otherwise delay (or lose) the flush.
    defer { notifier.finish() }

    return try await TestCompletionNotifier.$current.withValue(
        notifier,
        operation: operation,
        file: file,
        line: line
    )
}

/// The key of the identifier of the scope that finished, in the notification `userInfo`.
@_spi(Internals)
public let kTestScopeID = "kTestScopeID"

/// The identifier of the `@Suite(.finalizeSnapshots)` scope the current test runs in, if any.
@_spi(Internals)
public var currentTestCompletionScopeID: UUID? {
    TestCompletionNotifier.current?.id
}

/// Posts ``SwiftTestingDidFinishNotification`` when it is released.
///
/// One instance lives for as long as a suite that applies the finalize trait is running, so the
/// notification goes out when the suite ends.
final class TestCompletionNotifier: Sendable {

    @TaskLocal static var current: TestCompletionNotifier?

    let id = UUID()

    private let sourceLocation: SourceLocation

    fileprivate init(_ sourceLocation: SourceLocation) {
        self.sourceLocation = sourceLocation
    }

    fileprivate func finish() {
        NotificationCenter.default.post(
            name: SwiftTestingDidFinishNotification,
            object: nil,
            userInfo: [
                kTestFileName: sourceLocation.fileName,
                kTestScopeID: id,
            ]
        )
    }
}
#endif
