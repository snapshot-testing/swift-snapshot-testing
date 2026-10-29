import Foundation
import SwiftParser
import SwiftSyntax
@_spi(Internals) import XCSnapshotTesting

@testable import InlineSnapshotTesting

/// Runs the source rewriter over a string, the same way it rewrites a test file, without touching the disk.
enum RewriterHarness {

    /// Finds where a call to `name` ends, which is how snapshots identify the call they belong to.
    private final class CallFinder: SyntaxVisitor {
        let name: String
        let converter: SourceLocationConverter
        var locations: [(line: Int, column: Int)] = []

        init(name: String, converter: SourceLocationConverter) {
            self.name = name
            self.converter = converter
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if node.calledExpression.trimmedDescription == name {
                let end = node.calledExpression.endLocation(converter: converter, afterTrailingTrivia: true)
                locations.append((end.line, end.column))
            }
            return .visitChildren
        }
    }

    struct Snapshot {
        var reference: String? = "old"
        var diffable: Data = Data("new".utf8)
        var wasRecording = true
        var descriptor = SnapshotClosureDescriptor()
        /// Which of the calls to `assertInline` in the source this snapshot belongs to.
        var callIndex = 0
    }

    static func rewrite(_ source: String, call name: String = "assertInline", _ snapshots: Snapshot...) -> String {
        let sourceFile = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: "Test.swift", tree: sourceFile)

        let finder = CallFinder(name: name, converter: converter)
        finder.walk(sourceFile)

        let inlineSnapshots = snapshots.map { snapshot in
            let location = finder.locations[snapshot.callIndex]
            return InlineSnapshot(
                reference: snapshot.reference.map { Data($0.utf8) },
                diffable: snapshot.diffable,
                wasRecording: snapshot.wasRecording,
                closureDescriptor: snapshot.descriptor,
                function: "test()",
                line: UInt(location.line),
                column: UInt(location.column)
            )
        }

        let rewriter = SnapshotRewriter(
            file: SnapshotURL(path: "Test.swift"),
            snapshots: inlineSnapshots.sorted { $0.line < $1.line },
            sourceLocationConverter: converter
        )

        return rewriter.visit(sourceFile).description
    }

    /// The line a snapshot closure starts on, as the visitor reports it.
    static func trailingClosureLine(
        in source: String,
        call name: String = "assertInline",
        descriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor()
    ) -> Int? {
        let sourceFile = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: "Test.swift", tree: sourceFile)

        let finder = CallFinder(name: name, converter: converter)
        finder.walk(sourceFile)

        guard let location = finder.locations.first else { return nil }

        let visitor = SnapshotVisitor(
            functionCallLine: location.line,
            functionCallColumn: location.column,
            sourceLocationConverter: converter,
            closureDescriptor: descriptor
        )
        visitor.walk(sourceFile)
        return visitor.trailingClosureLine
    }
}
