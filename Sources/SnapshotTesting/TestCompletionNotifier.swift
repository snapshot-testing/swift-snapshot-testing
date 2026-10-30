// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

public struct FinalizeSnapshotsSuiteTrait: SuiteTrait {

    public let isRecursive = false

    public func scopeProvider(
        for test: Test,
        testCase: Test.Case?
    ) -> TestScopeProvider? {
        TestScopeProvider()
    }
}

extension Trait where Self == FinalizeSnapshotsSuiteTrait {

    /// A suite trait that finalizes all snapshot tests after the suite completes execution.
    ///
    /// Use this trait to automatically trigger snapshot finalization logic—
    /// such as emitting notifications or performing cleanup—after all tests
    /// in a suite have finished running. This is useful for ensuring that any
    /// resources or state associated with snapshot testing are properly handled
    /// after tests conclude.
    ///
    /// Apply this trait to your test suite using the `@Suite(.finalizeSnapshots)`
    /// macro.
    ///
    /// Example:
    /// ```swift
    /// @Suite(.finalizeSnapshots)
    /// struct MySnapshotTests { ... }
    /// ```
    ///
    /// - Note: This trait is non-recursive and will only apply to the suite where it is specified.
    public static var finalizeSnapshots: Self {
        .init()
    }
}

extension FinalizeSnapshotsSuiteTrait {

    public struct TestScopeProvider: TestScoping {

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
