// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
import SnapshotTesting
import Testing
@_spi(Internals) import XCSnapshotTesting

@_spi(Internals) @testable import InlineSnapshotTesting

extension InlineSnapshotManagerTests {

    /// Runs whole assertions against a copy of a test source in a temporary directory, so the snapshots
    /// they record are written there and not into the sources of this package.
    ///
    /// It lives inside ``InlineSnapshotManagerTests`` to run serialized with it: both change the current
    /// directory, which is how a `StaticString` path reaches the sample file.
    @Suite("Inline failure messages", .finalizeSnapshots)
    struct FailureMessages {

        /// Where the rewriter looks for the call on line 2 of the sources below: the column right after the
        /// name `assertInline`, which is also what `#column` reports for a call.
        private static let column: UInt = 17

        private static let missingSource = """
            func test() {
                assertInline(of: "x", as: .lines)
            }

            """

        private static let recordedSource = """
            func test() {
                assertInline(of: "x", as: .lines) {
                    \"\"\"
                    y
                    \"\"\"
                }
            }

            """

        /// Runs `body` with `source` saved as `Sample.swift` in the current directory, and returns what
        /// that file holds once the snapshots were written.
        private func withSample(
            _ source: String,
            _ body: () async throws -> Void
        ) async throws -> String {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try source.write(
                to: directory.appendingPathComponent("Sample.swift"),
                atomically: true,
                encoding: .utf8
            )

            let previous = FileManager.default.currentDirectoryPath
            #expect(FileManager.default.changeCurrentDirectoryPath(directory.path))

            defer {
                FileManager.default.changeCurrentDirectoryPath(previous)
                try? FileManager.default.removeItem(at: directory)
            }

            return try await withInlineSnapshotManager {
                try await body()
                InlineSnapshotManager.current.writeInlineSnapshots()
                return try String(contentsOfFile: "Sample.swift", encoding: .utf8)
            }
        }

        private func message(of issue: Issue) -> String {
            issue.comments.map(\.rawValue).joined(separator: "\n")
        }

        // MARK: - Missing reference

        @Test
        func aMissingSnapshotIsRecordedAndSaysSo() async throws {
            let written = try await withSample(Self.missingSource) {
                try withKnownIssue {
                    try assertInline(
                        of: "x",
                        as: .lines,
                        record: .missing,
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    let message = message(of: $0)
                    return message.contains("No reference was found on disk. Automatically recorded a new snapshot.")
                        && message.contains("Re-run \"")
                        && !message.contains("for \"")
                }
            }

            #expect(written.contains("assertInline(of: \"x\", as: .lines)"))
            #expect(written != Self.missingSource, "the snapshot is written into the source")
        }

        @Test
        func aMissingSnapshotNamesTheCustomClosureLabel() async throws {
            _ = try await withSample(Self.missingSource) {
                try withKnownIssue {
                    try assertInline(
                        of: "x",
                        as: .lines,
                        record: .missing,
                        closureDescriptor: SnapshotClosureDescriptor(trailingClosureLabel: "is"),
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    message(of: $0).contains("Automatically recorded a new snapshot for \"is\".")
                }
            }
        }

        @Test
        func aSnapshotThatCannotBeRecordedIsReportedAsMissing() async throws {
            _ = try await withSample(Self.missingSource) {
                try withKnownIssue {
                    try assertInline(
                        of: "x",
                        as: .lines,
                        record: .never,
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    message(of: $0).contains("New snapshot was not recorded because recording is disabled")
                }
            }
        }

        // MARK: - Record mode

        @Test
        func recordingEverythingReplacesTheSnapshotAndSaysSo() async throws {
            let written = try await withSample(Self.recordedSource) {
                try withKnownIssue {
                    try assertInline(
                        of: "x",
                        as: .lines,
                        record: .all,
                        matches: { "y" },
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    let message = message(of: $0)
                    return message.contains("Automatically recorded a new snapshot.")
                        && message.contains("Turn record mode off and re-run \"")
                }
            }

            #expect(written.contains("x\n"))
            #expect(!written.contains("y\n"))
        }

        @Test
        func recordingEverythingNamesTheCustomClosureLabel() async throws {
            _ = try await withSample(Self.recordedSource) {
                try withKnownIssue {
                    try assertInline(
                        of: "x",
                        as: .lines,
                        record: .all,
                        closureDescriptor: SnapshotClosureDescriptor(trailingClosureLabel: "is"),
                        matches: { "y" },
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    message(of: $0).contains("Automatically recorded a new snapshot for \"is\".")
                }
            }
        }

        // MARK: - Mismatch

        @Test
        func aMismatchThatWasRecordedOverSaysTheSnapshotWasReplaced() async throws {
            let written = try await withSample(Self.recordedSource) {
                try withKnownIssue {
                    try assertInline(
                        of: "x",
                        as: .lines,
                        message: "The text changed",
                        record: .failed,
                        matches: { "y" },
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    let message = message(of: $0)
                    return message.hasPrefix("The text changed")
                        && message.contains("A new snapshot was automatically recorded.")
                }
            }

            #expect(written.contains("x\n"))
        }

        @Test
        func aMismatchWithoutAMessageUsesTheDefaultOne() async throws {
            _ = try await withSample(Self.recordedSource) {
                try await withKnownIssue {
                    try await assertInline(
                        of: "x",
                        as: AsyncSnapshot<String, StringBytes>(
                            pathExtension: "txt",
                            attachmentGenerator: .lines,
                            executor: Async { StringBytes(rawValue: $0) }
                        ),
                        record: .never,
                        matches: { "y" },
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    message(of: $0).hasPrefix("Snapshot does not match reference. Difference: …")
                }
            }
        }

        // MARK: - Timeout

        @Test
        func aSnapshotThatTakesTooLongTimesOut() async throws {
            let slow = AsyncSnapshot<String, StringBytes>(
                pathExtension: "txt",
                attachmentGenerator: .lines,
                executor: Async {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    return StringBytes(rawValue: $0)
                }
            )

            _ = try await withSample(Self.missingSource) {
                try await withKnownIssue {
                    try await assertInline(
                        of: "x",
                        as: slow,
                        record: .never,
                        timeout: 0.05,
                        file: "Sample.swift",
                        line: 2,
                        column: Self.column
                    )
                } matching: {
                    message(of: $0).contains("Exceeded timeout of 0.05 seconds waiting for snapshot.")
                }
            }
        }

        // MARK: - Reference

        @Test
        func withoutALiteralOrARecordThereIsNothingToCompareWith() throws {
            try withInlineSnapshotManager {
                let engine = try SnapshotInlineEngine<Sync<String, StringBytes>>(
                    expected: nil,
                    message: { "" },
                    closureDescriptor: SnapshotClosureDescriptor(),
                    line: 1,
                    column: 1
                )
                let tester = SnapshotTester(
                    engine: engine,
                    record: nil,
                    timeout: 5,
                    name: nil,
                    serialization: DataSerialization(),
                    fileID: #fileID,
                    filePath: #filePath,
                    function: #function,
                    line: #line,
                    column: #column
                )
                let url = URL(fileURLWithPath: "/tmp/Sample.swift").appendingPathComponent("test.1")

                #expect(!engine.contentExists(at: url))
                #expect(throws: URLError.self) {
                    _ = try engine.loadSnapshot(from: url, using: tester)
                }
            }
        }
    }
}
