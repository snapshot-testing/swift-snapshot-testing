// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(SwiftSyntax601)
import SwiftSyntax
import Foundation
@_spi(Internals) import XCSnapshotTesting
#if canImport(Testing)
@_spi(Internals) import SnapshotTesting
#endif

/// Thrown instead of trapping, so a missing trait only fails the test that forgot it.
struct MissingFinalizeSnapshotsError: Error, CustomStringConvertible {
    var description: String {
        "To run InlineSnapshotTesting on Swift Testing, you need to add @Suite(.finalizeSnapshots)"
    }
}

struct SnapshotInlineEngine<Executor: SnapshotExecutor>: SnapshotEngine where Executor.Output: BytesRepresentable {

    let expected: (@Sendable () -> Executor.Output.RawValue)?
    let message: @Sendable () -> String
    let closureDescriptor: SnapshotClosureDescriptor

    init(
        expected: (@Sendable () -> Executor.Output.RawValue)?,
        message: @Sendable @escaping () -> String,
        closureDescriptor: SnapshotClosureDescriptor
    ) throws {
        SnapshotInlineObservation.shared.registerIfNeeded()
        if TestingSystem.shared.isSwiftTestingRunning,
            !TestingSystem.shared.isSwiftTestingCompletionAttached
        {
            throw MissingFinalizeSnapshotsError()
        }
        self.expected = expected
        self.message = message
        self.closureDescriptor = closureDescriptor
    }

    func sourceURL(
        for filePath: StaticString,
        using tester: SnapshotTester<SnapshotInlineEngine<Executor>>
    ) throws -> URL {
        #if canImport(Testing)
        let scope = currentTestCompletionScopeID
        #else
        let scope: UUID? = nil
        #endif

        try InlineSnapshotManager.current.registerTestSource(.init(path: filePath), scope: scope)

        return URL(
            fileURLWithPath: String(describing: filePath),
            isDirectory: false
        )
    }

    func temporaryURL(
        for filePath: StaticString,
        using tester: SnapshotTester<SnapshotInlineEngine<Executor>>
    ) throws -> URL? {
        nil
    }

    func contentExists(
        at url: URL
    ) -> Bool {
        expected != nil || InlineSnapshotManager.current.recordExists(at: url)
    }

    func loadSnapshot(
        from url: URL,
        using tester: SnapshotTester<SnapshotInlineEngine<Executor>>
    ) throws -> Executor.Output {
        // The inline literal is the reference whenever there is one. A record only stands in for it
        // when the literal is missing, and it must not replace it: the same call can run again (in a
        // loop or a parameterized test) and a record holds what an earlier run produced, not what
        // the test expects.
        if let expected {
            return Executor.Output(rawValue: expected())
        } else if InlineSnapshotManager.current.recordExists(at: url) {
            let snapshot = try InlineSnapshotManager.current.record(at: url)
            return try tester.serialization.deserialize(Executor.Output.self, from: snapshot.diffable)
        } else {
            throw URLError(.fileDoesNotExist)
        }
    }

    func perform(
        _ operation: SnapshotPerformOperation,
        contents: Data,
        to url: URL,
        using tester: SnapshotTester<SnapshotInlineEngine<Executor>>
    ) throws {
        InlineSnapshotManager.current.write(
            InlineSnapshot(
                reference: (try? InlineSnapshotManager.current.record(at: url))?.diffable,
                diffable: contents,
                wasRecording: operation == .write,
                closureDescriptor: closureDescriptor,
                function: String(describing: tester.function),
                line: tester.line,
                column: tester.column
            ),
            to: url
        )
    }

    func generateFailureMessage(
        for context: SnapshotFailContext,
        using tester: SnapshotTester<SnapshotInlineEngine<Executor>>
    ) -> String {
        switch context.reason {
        case .missing:
            return missing(context)
        case .doesNotMatch:
            return doesNotMatch(context)
        case .allRecordMode:
            return allRecordMode(context)
        case .timeout:
            return timeout(context, timeout: tester.timeout)
        }
    }
}

extension SnapshotInlineEngine {

    fileprivate func missing(_ context: SnapshotFailContext) -> String {
        let name = String(describing: context.function)

        guard context.didWriteNewSnapshot else {
            return
                "No reference was found on disk. New snapshot was not recorded because recording is disabled"
        }

        let failure: String
        if closureDescriptor.trailingClosureLabel
            == SnapshotClosureDescriptor.defaultTrailingClosureLabel
        {
            failure = "Automatically recorded a new snapshot."
        } else {
            failure = """
                Automatically recorded a new snapshot for "\(closureDescriptor.trailingClosureLabel)".
                """
        }

        return """
            No reference was found on disk. \(failure):

            Re-run "\(name)" to assert against the newly-recorded snapshot.
            """
    }

    fileprivate func doesNotMatch(_ context: SnapshotFailContext) -> String {
        var message: String = message()

        if message.isEmpty {
            message += "Snapshot does not match reference. Difference: …"
        }

        if let additionalInformation = context.additionalInformation {
            message += "\n\n" + additionalInformation.indenting(by: 2)
        }

        if context.didWriteNewSnapshot {
            message += "\n\nA new snapshot was automatically recorded."
        }

        return message
    }

    fileprivate func allRecordMode(_ context: SnapshotFailContext) -> String {
        let name = String(describing: context.function)

        let failure: String

        if closureDescriptor.trailingClosureLabel
            == SnapshotClosureDescriptor.defaultTrailingClosureLabel
        {
            failure = "Automatically recorded a new snapshot."
        } else {
            failure = """
                Automatically recorded a new snapshot for "\(closureDescriptor.trailingClosureLabel)".
                """
        }

        return """
            \(failure)

            Turn record mode off and re-run "\(name)" to assert against the newly-recorded snapshot
            """
    }

    fileprivate func timeout(_ context: SnapshotFailContext, timeout: TimeInterval) -> String {
        """
        Exceeded timeout of \(timeout) seconds waiting for snapshot.

        This can happen when an asynchronously loaded value (like a network response) has not \
        loaded. If a timeout is unavoidable, consider setting the "timeout" parameter of
        "assertInline" to a higher value.
        """
    }
}
#endif
