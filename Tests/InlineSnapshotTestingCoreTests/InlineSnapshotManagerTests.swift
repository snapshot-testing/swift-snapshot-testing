// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
import SwiftParser
import SwiftSyntax
import Testing

@_spi(Internals) @testable import InlineSnapshotTesting

/// The manager reads its file through a `StaticString` path, so the tests point it at a relative
/// path and run from a temporary directory. They must not overlap.
@Suite("Inline snapshot manager", .serialized)
struct InlineSnapshotManagerTests {

    private static let source = """
        func test() {
            assertInline(of: 1) {
                \"\"\"
                old
                \"\"\"
            }
            assertInline(of: 2) {
                \"\"\"
                old
                \"\"\"
            }
        }

        """

    private static let multiline = Data("first\nsecond\nthird".utf8)
    private static let single = Data("only".utf8)

    private func withSampleFile(
        _ contents: String = InlineSnapshotManagerTests.source,
        _ body: (InlineSnapshotManager) throws -> Void
    ) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try contents.write(
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

        try withInlineSnapshotManager {
            let manager = InlineSnapshotManager.current
            try body(manager)
            // Leaves nothing for `deinit` to write once the directory is gone.
            manager.writeInlineSnapshots()
        }
    }

    private func snapshot(_ callIndex: Int, _ diffable: Data) -> (URL, InlineSnapshot) {
        let location = RewriterHarness.callLocations(in: Self.source)[callIndex]
        return (
            URL(fileURLWithPath: "Sample.swift").appendingPathComponent("test.\(callIndex + 1)"),
            InlineSnapshot(
                reference: Data("old".utf8),
                diffable: diffable,
                wasRecording: true,
                closureDescriptor: SnapshotClosureDescriptor(),
                function: "test()",
                line: UInt(location.line),
                column: UInt(location.column)
            )
        )
    }

    private func contents() throws -> String {
        try String(contentsOfFile: "Sample.swift", encoding: .utf8)
    }

    @Test
    func aFileIsOnlyWrittenWhenTheLastScopeUsingItFinishes() throws {
        try withSampleFile { manager in
            let first = UUID()
            let second = UUID()

            try manager.registerTestSource(.init(path: "Sample.swift"), scope: first)
            try manager.registerTestSource(.init(path: "Sample.swift"), scope: second)

            let (url, value) = snapshot(0, Self.multiline)
            manager.write(value, to: url)

            manager.writeInlineSnapshots(scope: first)
            #expect(try contents() == Self.source, "another scope is still using the file")

            manager.writeInlineSnapshots(scope: second)
            #expect(try contents() != Self.source)
        }
    }

    @Test
    func laterScopesStillLandOnTheRightCallAfterTheFileWasRewritten() throws {
        try withSampleFile { manager in
            let first = UUID()
            let second = UUID()

            // The first scope grows the file by two lines before the second one finishes.
            try manager.registerTestSource(.init(path: "Sample.swift"), scope: first)
            let (firstURL, firstValue) = snapshot(0, Self.multiline)
            manager.write(firstValue, to: firstURL)
            manager.writeInlineSnapshots(scope: first)

            try manager.registerTestSource(.init(path: "Sample.swift"), scope: second)
            let (secondURL, secondValue) = snapshot(1, Self.single)
            manager.write(secondValue, to: secondURL)
            manager.writeInlineSnapshots(scope: second)

            let expected = RewriterHarness.rewrite(
                Self.source,
                RewriterHarness.Snapshot(diffable: Self.multiline, callIndex: 0),
                RewriterHarness.Snapshot(diffable: Self.single, callIndex: 1)
            )
            #expect(try contents() == expected)
        }
    }

    @Test
    func aFailedWriteIsReportedInsteadOfCrashing() throws {
        try withSampleFile { manager in
            let scope = UUID()
            try manager.registerTestSource(.init(path: "Sample.swift"), scope: scope)

            let (url, value) = snapshot(0, Self.multiline)
            manager.write(value, to: url)

            // The directory can no longer receive the temporary file of an atomic write.
            let directory = FileManager.default.currentDirectoryPath
            try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: directory)
            defer {
                try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory)
            }

            withKnownIssue {
                manager.writeInlineSnapshots(scope: scope)
            }
            #expect(try contents() == Self.source)
        }
    }

    @Test
    func aSnapshotWithoutACallDoesNotHoldBackTheOthers() {
        let sourceFile = Parser.parse(source: Self.source)
        let converter = SourceLocationConverter(fileName: "Test.swift", tree: sourceFile)
        let location = RewriterHarness.callLocations(in: Self.source)[1]

        func make(line: Int, column: Int, _ diffable: Data) -> InlineSnapshot {
            InlineSnapshot(
                reference: Data("old".utf8),
                diffable: diffable,
                wasRecording: true,
                closureDescriptor: SnapshotClosureDescriptor(),
                function: "test()",
                line: UInt(line),
                column: UInt(column)
            )
        }

        let rewriter = SnapshotRewriter(
            file: SnapshotURL(path: "Test.swift"),
            snapshots: [
                make(line: 1, column: 1, Data("orphan".utf8)),
                make(line: location.line, column: location.column, Self.single),
            ],
            sourceLocationConverter: converter
        )

        let result = rewriter.visit(sourceFile).description
        #expect(result.contains("only"))
        #expect(!result.contains("orphan"))
    }

    @Test
    func snapshotsOnTheSameLineAreMatchedByColumn() {
        let source = "func test() { assertInline(of: 1) { \"old\" }; assertInline(of: 2) { \"old\" } }\n"
        let sourceFile = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: "Test.swift", tree: sourceFile)
        let locations = RewriterHarness.callLocations(in: source)
        #expect(locations.count == 2)
        #expect(locations[0].line == locations[1].line)

        func make(_ location: (line: Int, column: Int), _ text: String) -> InlineSnapshot {
            InlineSnapshot(
                reference: Data("old".utf8),
                diffable: Data(text.utf8),
                wasRecording: true,
                closureDescriptor: SnapshotClosureDescriptor(),
                function: "test()",
                line: UInt(location.line),
                column: UInt(location.column)
            )
        }

        // The second call comes first in the list, as an unordered dictionary may return it.
        let rewriter = SnapshotRewriter(
            file: SnapshotURL(path: "Test.swift"),
            snapshots: [make(locations[1], "second"), make(locations[0], "first")],
            sourceLocationConverter: converter
        )

        let result = rewriter.visit(sourceFile).description
        #expect(result.contains("first"))
        #expect(result.contains("second"))
    }
}
