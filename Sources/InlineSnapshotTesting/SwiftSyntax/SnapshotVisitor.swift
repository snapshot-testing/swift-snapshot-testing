// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(SwiftSyntax601)
import SwiftSyntax

/// Finds the line of the closure that holds the snapshot of an assertion.
///
/// Failures are reported on that line instead of on the line of the call.
final class SnapshotVisitor: SyntaxVisitor {

    let functionCallColumn: Int
    let functionCallLine: Int
    let sourceLocationConverter: SourceLocationConverter
    let closureDescriptor: SnapshotClosureDescriptor
    var trailingClosureLine: Int?

    init(
        functionCallLine: Int,
        functionCallColumn: Int,
        sourceLocationConverter: SourceLocationConverter,
        closureDescriptor: SnapshotClosureDescriptor
    ) {
        self.functionCallColumn = functionCallColumn
        self.functionCallLine = functionCallLine
        self.sourceLocationConverter = sourceLocationConverter
        self.closureDescriptor = closureDescriptor
        super.init(viewMode: .all)
    }

    /// Looks for the call at the given line and column, and stores the line of its snapshot closure
    /// in ``trailingClosureLine``. It follows the same offset rules as ``SnapshotRewriter``.
    override func visit(_ functionCallExpr: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let location = functionCallExpr.calledExpression.endLocation(
            converter: self.sourceLocationConverter,
            afterTrailingTrivia: true
        )

        guard
            self.functionCallLine == location.line,
            self.functionCallColumn == location.column
        else { return .visitChildren }

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
            + max(0, self.closureDescriptor.trailingClosureOffset)

        let centeredTrailingClosureOffset = trailingClosureOffset - arguments.count

        switch centeredTrailingClosureOffset {
        case ..<0:
            let index = arguments.index(arguments.startIndex, offsetBy: trailingClosureOffset)
            self.trailingClosureLine =
                arguments[index]
                .startLocation(converter: self.sourceLocationConverter)
                .line

        case 0:
            self.trailingClosureLine = functionCallExpr.trailingClosure.map {
                $0.startLocation(converter: self.sourceLocationConverter).line
            }

        case 1...:
            let index = functionCallExpr.additionalTrailingClosures.index(
                functionCallExpr.additionalTrailingClosures.startIndex,
                offsetBy: centeredTrailingClosureOffset - 1
            )
            if centeredTrailingClosureOffset - 1 < functionCallExpr.additionalTrailingClosures.count {
                self.trailingClosureLine =
                    functionCallExpr.additionalTrailingClosures[index]
                    .startLocation(converter: self.sourceLocationConverter)
                    .line
            }
        default:
            break
        }
        return .skipChildren
    }
}
#endif
