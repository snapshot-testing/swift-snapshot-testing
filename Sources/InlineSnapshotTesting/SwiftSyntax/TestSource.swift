// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(SwiftSyntax601)
import SwiftSyntax

/// A test file, parsed once.
///
/// It keeps the syntax tree and the converter that maps positions in the tree to lines and columns.
struct TestSource {
    let source: String
    let sourceFile: SourceFileSyntax
    let sourceLocationConverter: SourceLocationConverter
}
#endif
