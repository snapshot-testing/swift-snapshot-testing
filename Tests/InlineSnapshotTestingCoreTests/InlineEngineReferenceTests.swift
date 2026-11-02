// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
import SnapshotTesting
import Testing
@_spi(Internals) import XCSnapshotTesting

@_spi(Internals) @testable import InlineSnapshotTesting

@Suite("Inline reference", .finalizeSnapshots)
struct InlineEngineReferenceTests {

    private func tester(
        _ engine: SnapshotInlineEngine<Sync<String, StringBytes>>
    ) -> SnapshotTester<SnapshotInlineEngine<Sync<String, StringBytes>>> {
        SnapshotTester(
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
    }

    @Test
    func theInlineLiteralWinsOverWhatAnEarlierRunRecorded() throws {
        try withInlineSnapshotManager {
            let engine = try SnapshotInlineEngine<Sync<String, StringBytes>>(
                expected: { "expected" },
                message: { "" },
                closureDescriptor: SnapshotClosureDescriptor(),
                line: 1,
                column: 1
            )
            let url = URL(fileURLWithPath: "/tmp/Sample.swift").appendingPathComponent("test.1")

            InlineSnapshotManager.current.write(
                InlineSnapshot(
                    reference: nil,
                    diffable: Data("an earlier run".utf8),
                    wasRecording: false,
                    closureDescriptor: SnapshotClosureDescriptor(),
                    function: "test()",
                    line: 1,
                    column: 1
                ),
                to: engine.storageURL(for: url)
            )

            let reference = try engine.loadSnapshot(from: url, using: tester(engine))
            #expect(reference.rawValue == "expected")
        }
    }

    @Test
    func theRecordIsTheReferenceWhenThereIsNoLiteral() throws {
        try withInlineSnapshotManager {
            let engine = try SnapshotInlineEngine<Sync<String, StringBytes>>(
                expected: nil,
                message: { "" },
                closureDescriptor: SnapshotClosureDescriptor(),
                line: 1,
                column: 1
            )
            let url = URL(fileURLWithPath: "/tmp/Sample.swift").appendingPathComponent("test.1")

            InlineSnapshotManager.current.write(
                InlineSnapshot(
                    reference: nil,
                    diffable: Data("recorded".utf8),
                    wasRecording: true,
                    closureDescriptor: SnapshotClosureDescriptor(),
                    function: "test()",
                    line: 1,
                    column: 1
                ),
                to: engine.storageURL(for: url)
            )

            let reference = try engine.loadSnapshot(from: url, using: tester(engine))
            #expect(reference.rawValue == "recorded")
        }
    }

    @Test
    func twoAssertionsSharingAURLKeepTheirOwnRecords() throws {
        try withInlineSnapshotManager {
            let first = try SnapshotInlineEngine<Sync<String, StringBytes>>(
                expected: nil,
                message: { "" },
                closureDescriptor: SnapshotClosureDescriptor(),
                line: 10,
                column: 5
            )
            let second = try SnapshotInlineEngine<Sync<String, StringBytes>>(
                expected: nil,
                message: { "" },
                closureDescriptor: SnapshotClosureDescriptor(),
                line: 20,
                column: 5
            )
            // `addsCounterSuffix = false` gives both assertions of a function the same URL.
            let url = URL(fileURLWithPath: "/tmp/Sample.swift").appendingPathComponent("test")

            try first.perform(
                .write,
                contents: Data("from the first".utf8),
                to: url,
                using: tester(first)
            )

            #expect(first.contentExists(at: url))
            #expect(!second.contentExists(at: url), "the second assertion has not recorded anything")

            try second.perform(
                .write,
                contents: Data("from the second".utf8),
                to: url,
                using: tester(second)
            )

            #expect(try first.loadSnapshot(from: url, using: tester(first)).rawValue == "from the first")
            #expect(try second.loadSnapshot(from: url, using: tester(second)).rawValue == "from the second")
            #expect(InlineSnapshotManager.current.records(for: "/tmp/Sample.swift").count == 2)
        }
    }
}
