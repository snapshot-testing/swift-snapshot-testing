// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(SwiftSyntax601)
import SwiftSyntax

final class SnapshotRewriter: SyntaxRewriter {

    let file: SnapshotURL
    var function: String?
    let indent: String
    let line: UInt?
    var newRecordings: [(snapshot: InlineSnapshot, line: UInt)] = []
    var snapshots: [InlineSnapshot]
    let sourceLocationConverter: SourceLocationConverter
    let wasRecording: Bool

    init(
        file: SnapshotURL,
        snapshots: [InlineSnapshot],
        sourceLocationConverter: SourceLocationConverter
    ) {
        self.file = file
        self.line = snapshots.first?.line
        self.wasRecording = snapshots.contains(where: \.wasRecording)
        self.indent = String(
            sourceLocationConverter.sourceLines
                .first { $0.first?.isWhitespace == true && $0.contains { !$0.isWhitespace } }?
                .prefix { $0.isWhitespace }
                ?? "    "
        )
        self.snapshots = snapshots
        self.sourceLocationConverter = sourceLocationConverter
    }

    override func visit(_ functionCallExpr: FunctionCallExprSyntax) -> ExprSyntax {
        let location = functionCallExpr.calledExpression
            .endLocation(converter: self.sourceLocationConverter, afterTrailingTrivia: true)

        // A snapshot that never finds its call must not hold back the ones that come after it.
        let isAtLocation: (InlineSnapshot) -> Bool = { snapshot in
            Int(snapshot.line) == location.line && Int(snapshot.column) == location.column
        }

        let snapshots = self.snapshots.filter(isAtLocation)

        guard !snapshots.isEmpty
        else { return super.visit(functionCallExpr) }

        defer { self.snapshots.removeAll(where: isAtLocation) }

        var functionCallExpr = functionCallExpr
        for snapshot in snapshots {
            guard snapshot.reference != snapshot.diffable, snapshot.wasRecording else { continue }

            // A value that is not text cannot be written inline; the existing closure stays as is.
            guard let diffable = String(data: snapshot.diffable, encoding: .utf8) else { continue }

            self.function =
                self.function
                ?? functionCallExpr.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text

            let leadingTrivia = String(
                self.sourceLocationConverter.sourceLines[Int(snapshot.line) - 1]
                    .prefix(while: { $0 == " " || $0 == "\t" })
            )
            let delimiter = String(
                repeating: "#",
                count: diffable.hashCount(isMultiline: true)
            )
            let leadingIndent = leadingTrivia + self.indent
            let snapshotLabel = TokenSyntax(
                stringLiteral: snapshot.closureDescriptor.trailingClosureLabel
            )
            let snapshotClosure: ClosureExprSyntax = {
                let actual = diffable
                return ClosureExprSyntax(
                    leftBrace: .leftBraceToken(trailingTrivia: .newline),
                    statements: CodeBlockItemListSyntax {
                        StringLiteralExprSyntax(
                            leadingTrivia: Trivia(stringLiteral: leadingIndent),
                            openingPounds: .rawStringPoundDelimiter(delimiter),
                            openingQuote: .multilineStringQuoteToken(trailingTrivia: .newline),
                            segments: [
                                .stringSegment(
                                    StringSegmentSyntax(
                                        content: .stringSegment(
                                            actual
                                                .replacingOccurrences(of: "\r", with: #"\\#(delimiter)r"#)
                                                .indenting(with: leadingIndent)
                                        )
                                    )
                                )
                            ],
                            closingQuote: .multilineStringQuoteToken(
                                leadingTrivia: .newline + Trivia(stringLiteral: leadingIndent)
                            ),
                            closingPounds: .rawStringPoundDelimiter(delimiter)
                        )
                    },
                    rightBrace: .rightBraceToken(
                        leadingTrivia: .newline + Trivia(stringLiteral: leadingTrivia)
                    )
                )
            }()

            let arguments = functionCallExpr.arguments
            let firstTrailingClosureOffset =
                arguments
                .enumerated()
                .reversed()
                .prefix(while: { $0.element.expression.is(ClosureExprSyntax.self) })
                .last?
                .offset ?? arguments.count

            let trailingClosureOffset =
                firstTrailingClosureOffset
                + snapshot.closureDescriptor.trailingClosureOffset

            let centeredTrailingClosureOffset = trailingClosureOffset - arguments.count

            switch centeredTrailingClosureOffset {
            case ..<0:
                let index = arguments.index(arguments.startIndex, offsetBy: trailingClosureOffset)
                functionCallExpr.arguments[index].label = snapshotLabel
                functionCallExpr.arguments[index].expression = ExprSyntax(snapshotClosure)

            case 0:
                functionCallExpr.rightParen?.trailingTrivia = .space
                let trailingClosureTrivia = functionCallExpr.trailingClosure?.trailingTrivia
                // FIXME: ?? multipleTrailingClosures.removeFirst()
                functionCallExpr.trailingClosure =
                    if let trailingClosureTrivia, trailingClosureTrivia.count > 0 {
                        snapshotClosure.with(
                            \.trailingTrivia,
                            snapshotClosure.trailingTrivia + trailingClosureTrivia
                        )
                    } else {
                        snapshotClosure
                    }

            default:
                let newElement = MultipleTrailingClosureElementSyntax(
                    label: snapshotLabel,
                    closure: snapshotClosure.with(
                        \.leadingTrivia,
                        snapshotClosure.leadingTrivia + .space
                    )
                )

                if !functionCallExpr.additionalTrailingClosures.isEmpty,
                    let endIndex = functionCallExpr.additionalTrailingClosures.index(
                        functionCallExpr.additionalTrailingClosures.endIndex,
                        offsetBy: -1,
                        limitedBy: functionCallExpr.additionalTrailingClosures.startIndex
                    ),
                    let index = functionCallExpr.additionalTrailingClosures.index(
                        functionCallExpr.additionalTrailingClosures.startIndex,
                        offsetBy: centeredTrailingClosureOffset - 1,
                        limitedBy: endIndex
                    )
                {
                    if snapshot.closureDescriptor.contains(
                        functionCallExpr.additionalTrailingClosures[index].label.text
                    ) {
                        functionCallExpr.additionalTrailingClosures[index].label = snapshotLabel
                        let trailingTrivia = functionCallExpr.additionalTrailingClosures[index].closure
                            .trailingTrivia
                        functionCallExpr.additionalTrailingClosures[index].closure =
                            if trailingTrivia.count > 0 {
                                snapshotClosure.with(
                                    \.trailingTrivia,
                                    snapshotClosure.trailingTrivia + trailingTrivia
                                )
                            } else {
                                snapshotClosure
                            }
                    } else {
                        functionCallExpr.additionalTrailingClosures.insert(
                            newElement.with(\.trailingTrivia, .space),
                            at: index
                        )
                    }
                } else {
                    if let index = functionCallExpr.additionalTrailingClosures.index(
                        functionCallExpr.additionalTrailingClosures.endIndex,
                        offsetBy: -1,
                        limitedBy: functionCallExpr.additionalTrailingClosures.startIndex
                    ) {
                        functionCallExpr.additionalTrailingClosures[index].trailingTrivia = .space
                    } else {
                        functionCallExpr.trailingClosure?.trailingTrivia = .space
                    }
                    functionCallExpr.additionalTrailingClosures.append(newElement)
                }
            }
        }

        if functionCallExpr.arguments.isEmpty,
            functionCallExpr.trailingClosure != nil,
            functionCallExpr.leftParen != nil,
            functionCallExpr.rightParen != nil
        {
            functionCallExpr.leftParen = nil
            functionCallExpr.rightParen = nil
            functionCallExpr.calledExpression.trailingTrivia = .space
        }

        return ExprSyntax(functionCallExpr)
    }
}
#endif
