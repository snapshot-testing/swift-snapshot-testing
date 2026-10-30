// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(SwiftSyntax601)
import Foundation
import SwiftSyntax
import SwiftParser
@_spi(Internals) import XCSnapshotTesting

final class InlineSnapshotManager: @unchecked Sendable {

    static var current: InlineSnapshotManager {
        local ?? shared
    }

    @TaskLocal
    fileprivate static var local: InlineSnapshotManager?

    private static let shared = InlineSnapshotManager()

    private let lock = NSLock()

    private var _snapshots: [URL: InlineSnapshot] = [:]
    private var _testSourceCache: [SnapshotURL: TestSource] = [:]

    /// The Swift Testing scopes that still have to finish before a file can be written.
    private var _pendingScopes: [SnapshotURL: Set<UUID>] = [:]

    /// What was last written to each file, so it is not rewritten with the same contents.
    private var _writtenSources: [SnapshotURL: String] = [:]

    fileprivate init() {}

    subscript(_ url: SnapshotURL) -> TestSource? {
        lock.withLock {
            _testSourceCache[url]
        }
    }

    /// Reads and parses the test file the first time it is seen.
    ///
    /// - Parameter scope: The Swift Testing scope the assertion runs in. The file is only written
    ///   once every scope that used it has finished.
    func registerTestSource(_ url: SnapshotURL, scope: UUID? = nil) throws {
        try lock.withLock {
            if _testSourceCache[url] == nil {
                let path = String(describing: url.path)

                let source = try String(contentsOfFile: path)

                let sourceFile = Parser.parse(source: source)

                let sourceLocationConverter = SourceLocationConverter(
                    fileName: path,
                    tree: sourceFile
                )

                _testSourceCache[url] = TestSource(
                    source: source,
                    sourceFile: sourceFile,
                    sourceLocationConverter: sourceLocationConverter
                )
            }

            if let scope {
                _pendingScopes[url, default: []].insert(scope)
            }
        }
    }

    func write(_ snapshot: InlineSnapshot, to url: URL) {
        lock.withLock {
            _snapshots[url] = snapshot
        }
    }

    func record(at url: URL) throws -> InlineSnapshot {
        try lock.withLock {
            guard let snapshot = _snapshots[url] else {
                throw URLError(.fileDoesNotExist)
            }

            return snapshot
        }
    }

    func recordExists(
        at url: URL
    ) -> Bool {
        lock.withLock {
            _snapshots[url] != nil
        }
    }

    /// Writes every pending file. Used when the whole test bundle finishes.
    func writeInlineSnapshots() {
        lock.withLock {
            while let (url, testSource) = _testSourceCache.popFirst() {
                _writeInlineSnapshots(
                    _records(for: url.path),
                    at: url,
                    testSource: testSource
                )
            }

            _pendingScopes.removeAll()
            _writtenSources.removeAll()
        }
    }

    /// Marks a Swift Testing scope as finished and writes the files no other scope is using.
    ///
    /// The line and column of a snapshot refer to the file as it was compiled, so the original
    /// source is kept and every write starts from it, never from a file that was already rewritten.
    func writeInlineSnapshots(scope: UUID) {
        lock.withLock {
            for (url, scopes) in _pendingScopes where scopes.contains(scope) {
                var scopes = scopes
                scopes.remove(scope)

                guard scopes.isEmpty else {
                    _pendingScopes[url] = scopes
                    continue
                }

                _pendingScopes[url] = nil

                guard let testSource = _testSourceCache[url] else {
                    continue
                }

                _writeInlineSnapshots(
                    _records(for: url.path),
                    at: url,
                    testSource: testSource
                )
            }
        }
    }

    func records(for filePath: StaticString) -> [InlineSnapshot] {
        lock.withLock {
            _records(for: filePath)
        }
    }

    // MARK: - Unsafe methods

    private func _records(for filePath: StaticString) -> [InlineSnapshot] {
        let url = URL(fileURLWithPath: String(describing: filePath))

        var records = [InlineSnapshot]()
        for (snapshotURL, snapshot) in _snapshots
        where snapshotURL.absoluteString.starts(with: url.absoluteString) {
            records.append(snapshot)
        }
        return records
    }

    private func _writeInlineSnapshots(
        _ snapshots: [InlineSnapshot],
        at url: SnapshotURL,
        testSource: TestSource
    ) {
        guard !snapshots.isEmpty else {
            return
        }

        let snapshotRewriter = SnapshotRewriter(
            file: url,
            snapshots: snapshots.sorted {
                if $0.line != $1.line {
                    return $0.line < $1.line
                }

                if $0.column != $1.column {
                    return $0.column < $1.column
                }

                return $0.closureDescriptor.trailingClosureOffset
                    < $1.closureDescriptor.trailingClosureOffset
            },
            sourceLocationConverter: testSource.sourceLocationConverter
        )

        let updatedSource = snapshotRewriter.visit(testSource.sourceFile).description

        guard updatedSource != (_writtenSources[url] ?? testSource.source) else {
            return
        }

        do {
            try updatedSource.write(
                toFile: String(describing: url.path),
                atomically: true,
                encoding: .utf8
            )
            _writtenSources[url] = updatedSource
        } catch {
            let message = "Could not write the inline snapshots to \(url.path): \(error)"
            FileHandle.standardError.write(Data((message + "\n").utf8))

            try? TestingSystem.shared.record(
                message: message,
                fileID: #fileID,
                filePath: url.path,
                line: max(snapshots.first?.line ?? 1, 1),
                column: 1
            )
        }
    }

    deinit {
        writeInlineSnapshots()
    }
}

@_spi(Internals)
public nonisolated(nonsending) func withInlineSnapshotManager<R: Sendable>(
    _ operation: nonisolated(nonsending) () async throws -> R,
    file: String = #file,
    line: UInt = #line
) async rethrows -> R {
    try await InlineSnapshotManager.$local.withValue(
        InlineSnapshotManager(),
        operation: operation,
        file: file,
        line: line
    )
}

@_spi(Internals)
public func withInlineSnapshotManager<R>(
    _ operation: () throws -> R,
    file: String = #file,
    line: UInt = #line
) rethrows -> R {
    try InlineSnapshotManager.$local.withValue(
        InlineSnapshotManager(),
        operation: operation,
        file: file,
        line: line
    )
}
#endif
