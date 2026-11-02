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

    @Test func hashesAfterABackslashNeedALongerDelimiter() {
        // `\#(` would be an interpolation inside `#"""`, so the delimiter must be at least `##`.
        #expect("C:\\#(dir)\\file".hashCount(isMultiline: true) == 2)
        #expect("a\\##b".hashCount(isMultiline: true) == 3)
        #expect("a\\#".hashCount(isMultiline: true) == 2)
        #expect("a # b \\ c".hashCount(isMultiline: true) == 1)
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

    // MARK: - Same results as the regular expressions they replaced

    /// The implementation that used a regular expression, kept to check the scan against it.
    private func regexHashCount(_ text: String, isMultiline: Bool) -> Int {
        let (quote, offset) = isMultiline ? ("\"\"\"", 2) : ("\"", 0)
        var substring = text[...]
        var hashCount = text.escapeHashCount()
        while let range = substring.range(of: "(\(quote)[#]*)", options: .regularExpression) {
            hashCount = max(substring.distance(from: range.lowerBound, to: range.upperBound) - offset, hashCount)
            substring = substring[range.upperBound...]
        }
        return hashCount
    }

    private func regexIndenting(_ text: String, with prefix: String) -> String {
        text.replacingOccurrences(of: #"([^\n]+)"#, with: "\(prefix)$1", options: .regularExpression)
    }

    @Test func theQuoteScanMatchesTheRegularExpression() {
        var generator = SystemRandomNumberGenerator()
        let alphabet = ["\"", "\"", "\"", "#", "#", "\\", "a", " ", "\n"]

        for _ in 0..<2_000 {
            let text = (0..<Int.random(in: 0...14, using: &generator))
                .map { _ in alphabet.randomElement(using: &generator)! }
                .joined()

            for isMultiline in [true, false] {
                #expect(
                    text.hashCount(isMultiline: isMultiline) == regexHashCount(text, isMultiline: isMultiline),
                    "\(text.debugDescription), multiline: \(isMultiline)"
                )
            }
        }
    }

    @Test func indentingMatchesTheRegularExpression() {
        var generator = SystemRandomNumberGenerator()
        let alphabet = ["a", "b", " ", "\n", "\n", "\t"]

        for _ in 0..<2_000 {
            let text = (0..<Int.random(in: 0...12, using: &generator))
                .map { _ in alphabet.randomElement(using: &generator)! }
                .joined()

            #expect(text.indenting(with: "    ") == regexIndenting(text, with: "    "), "\(text.debugDescription)")
        }
    }

    @Test func indentingTreatsACarriageReturnAsPartOfTheLine() {
        // "\r\n" is a single grapheme, but the lines are split at the line feed on every platform.
        #expect("a\r\nb".indenting(with: "  ") == "  a\r\n  b")
        #expect("\r\n\r\n".indenting(with: "  ") == "  \r\n  \r\n")
    }

    @Test func indentingKeepsADollarSignAndABackslashInThePrefix() {
        // The regular expression read the prefix as a template, where these characters are special.
        #expect("a\nb".indenting(with: "$1\\") == "$1\\a\n$1\\b")
    }
}
