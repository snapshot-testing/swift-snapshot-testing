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
                closureDescriptor: SnapshotClosureDescriptor()
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
                to: url
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
                closureDescriptor: SnapshotClosureDescriptor()
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
                to: url
            )

            let reference = try engine.loadSnapshot(from: url, using: tester(engine))
            #expect(reference.rawValue == "recorded")
        }
    }
}
