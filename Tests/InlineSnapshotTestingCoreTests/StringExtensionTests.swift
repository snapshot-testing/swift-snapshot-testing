// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Testing

@testable import InlineSnapshotTesting

@Suite("String helpers")
struct StringExtensionTests {

    @Test func indentingPrefixesEveryNonEmptyLine() {
        #expect("a\nb".indenting(by: 2) == "  a\n  b")
        #expect("a\n\nb".indenting(with: "\t") == "\ta\n\n\tb")
    }

    @Test func indentingWithAnEmptyPrefixChangesNothing() {
        #expect("a\nb".indenting(with: "") == "a\nb")
        #expect("a\nb".indenting(by: 0) == "a\nb")
    }

    @Test func plainTextNeedsNoDelimiter() {
        #expect("plain text".hashCount(isMultiline: true) == 0)
        #expect("quote \" alone".hashCount(isMultiline: true) == 0)
    }

    @Test func backslashesNeedOneHash() {
        #expect("a\\b".hashCount(isMultiline: true) == 1)
    }

    @Test func tripleQuotesNeedOneHash() {
        #expect("x \"\"\" y".hashCount(isMultiline: true) == 1)
    }

    @Test func tripleQuotesFollowedByHashesNeedOneMoreHash() {
        // The delimiter has to be longer than any run of hashes that follows a closing quote sequence.
        #expect("x \"\"\"# y".hashCount(isMultiline: true) == 2)
        #expect("x \"\"\"## y".hashCount(isMultiline: true) == 3)
    }

    @Test func singleLineStringsCareAboutSingleQuotes() {
        #expect("plain".hashCount(isMultiline: false) == 0)
        #expect("x \" y".hashCount(isMultiline: false) == 1)
        #expect("x \"# y".hashCount(isMultiline: false) == 2)
        #expect("x \"### y".hashCount(isMultiline: false) == 4)
    }
}
