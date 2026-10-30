// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
import SnapshotTesting
import Testing
@_spi(Internals) import XCSnapshotTesting

/// Swift Testing is the test system for this package, so failures go through `Issue.record` and
/// attachments through `Attachment.record`.
@Suite("Swift Testing integration")
struct TestingSystemTests {

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func swiftTestingIsDetectedAsTheRunningSystem() {
        #expect(TestingSystem.shared.isSwiftTestingRunning)
        #expect(!TestingSystem.shared.isSwiftTestingCompletionAttached, "no suite asked for completion tracking")
    }

    @Test func failuresAreRecordedAsIssues() throws {
        try withKnownIssue {
            try TestingSystem.shared.record(
                message: "custom failure",
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column
            )
        } matching: {
            $0.comments.first?.rawValue == "custom failure"
        }
    }

    @Test func attachmentsAreRecordedWithTheirNames() {
        TestingSystem.shared.add(
            "Attached",
            attachments: [
                SnapshotAttachment(string: "text"),
                SnapshotAttachment(uniformTypeIdentifier: "public.json", name: "named", payload: Data("{}".utf8)),
                SnapshotAttachment(uniformTypeIdentifier: nil, name: "without payload", payload: nil),
            ],
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column
        )
    }

    // MARK: - assert

    @Test func aMissingReferenceFailsTheTestAndTheRecordedOneMatchesNextTime() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try withKnownIssue {
            try assert(of: "value", as: .lines, named: "a", record: .missing, snapshotDirectory: directory.path)
        } matching: {
            ($0.comments.first?.rawValue ?? "").contains("Automatically recorded snapshot")
        }

        try assert(of: "value", as: .lines, named: "a", record: .never, snapshotDirectory: directory.path)
    }

    @Test func aMismatchFailsTheTestWithTheDiff() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try withKnownIssue {
            try assert(of: "first", as: .lines, named: "a", record: .missing, snapshotDirectory: directory.path)
        }

        try withKnownIssue {
            try assert(of: "second", as: .lines, named: "a", record: .never, snapshotDirectory: directory.path)
        } matching: {
            ($0.comments.first?.rawValue ?? "").contains("does not match reference.")
        }
    }

    @Test func asyncAssertionsReportThroughSwiftTesting() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let snapshot = AsyncSnapshot<String, StringBytes>(
            pathExtension: "txt",
            attachmentGenerator: .lines,
            executor: Async { StringBytes(rawValue: $0) }
        )

        try await withKnownIssue {
            try await assert(
                of: "value",
                as: snapshot,
                named: "a",
                record: .never,
                snapshotDirectory: directory.path
            )
        } matching: {
            ($0.comments.first?.rawValue ?? "").contains("No reference was found on disk")
        }
    }
}
