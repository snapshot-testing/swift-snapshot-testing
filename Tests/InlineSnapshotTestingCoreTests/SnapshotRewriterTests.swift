// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

@testable import InlineSnapshotTesting

@Suite("Inline snapshot rewriter")
struct SnapshotRewriterTests {

    private typealias Harness = RewriterHarness

    // MARK: - Existing closure

    @Test func theExpectedValueOfAnExistingClosureIsReplaced() {
        let source = """
            func test() {
                assertInline(of: "x") {
                    \"\"\"
                    old
                    \"\"\"
                }
            }
            """

        #expect(
            Harness.rewrite(source, Harness.Snapshot())
                == """
                func test() {
                    assertInline(of: "x") {
                        \"\"\"
                        new
                        \"\"\"
                    }
                }
                """
        )
    }

    @Test func multilineValuesKeepTheirIndentation() {
        let source = """
            func test() {
                assertInline(of: "x") {
                    \"\"\"
                    old
                    \"\"\"
                }
            }
            """

        let result = Harness.rewrite(source, Harness.Snapshot(diffable: Data("one\ntwo\n\nfour".utf8)))

        #expect(result.contains("        one\n        two\n\n        four\n"))
    }

    @Test func tabsAreUsedForIndentationWhenTheFileUsesTabs() {
        let source = "func test() {\n\tassertInline(of: \"x\") {\n\t\t\"\"\"\n\t\told\n\t\t\"\"\"\n\t}\n}"

        let result = Harness.rewrite(source, Harness.Snapshot())

        #expect(result.contains("\t\t\"\"\"\n\t\tnew\n\t\t\"\"\""))
    }

    // MARK: - No closure yet

    @Test func aClosureIsAddedWhenTheCallHasNone() {
        let source = """
            func test() {
                assertInline(of: "x")
            }
            """

        #expect(
            Harness.rewrite(source, Harness.Snapshot(reference: nil))
                == """
                func test() {
                    assertInline(of: "x") {
                        \"\"\"
                        new
                        \"\"\"
                    }
                }
                """
        )
    }

    @Test func aLabeledClosureArgumentIsReplacedInPlace() {
        let source = """
            func test() {
                assertInline(of: "x", matches: {
                    \"\"\"
                    old
                    \"\"\"
                })
            }
            """

        let result = Harness.rewrite(source, Harness.Snapshot())

        #expect(result.contains("assertInline(of: \"x\", matches: {"))
        #expect(result.contains("new"))
        #expect(!result.contains("old"))
    }

    // MARK: - Strings that need escaping

    @Test func valuesWithTripleQuotesUseRawStringDelimiters() {
        let source = "func test() {\n    assertInline(of: \"x\")\n}"

        let result = Harness.rewrite(
            source,
            Harness.Snapshot(reference: nil, diffable: Data("say \"\"\"hi\"\"\"".utf8))
        )

        #expect(result.contains("#\"\"\"\n"))
        #expect(result.contains("\"\"\"#"))
        #expect(result.contains("say \"\"\"hi\"\"\""))
    }

    @Test func valuesWithBackslashesUseRawStringDelimiters() {
        let source = "func test() {\n    assertInline(of: \"x\")\n}"

        let result = Harness.rewrite(source, Harness.Snapshot(reference: nil, diffable: Data("a\\nb".utf8)))

        #expect(result.contains("#\"\"\""))
        #expect(result.contains("a\\nb"))
    }

    @Test func carriageReturnsAreEscaped() {
        let source = "func test() {\n    assertInline(of: \"x\")\n}"

        let result = Harness.rewrite(source, Harness.Snapshot(reference: nil, diffable: Data("a\r\nb".utf8)))

        #expect(result.contains("a\\r"))
        #expect(!result.contains("\r"))
    }

    // MARK: - Snapshots that must not change the source

    @Test func equalValuesLeaveTheSourceUntouched() {
        let source =
            "func test() {\n    assertInline(of: \"x\") {\n        \"\"\"\n        same\n        \"\"\"\n    }\n}"

        let result = Harness.rewrite(
            source,
            Harness.Snapshot(reference: "same", diffable: Data("same".utf8))
        )

        #expect(result == source)
    }

    @Test func snapshotsThatWereNotRecordingLeaveTheSourceUntouched() {
        let source =
            "func test() {\n    assertInline(of: \"x\") {\n        \"\"\"\n        old\n        \"\"\"\n    }\n}"

        let result = Harness.rewrite(source, Harness.Snapshot(wasRecording: false))

        #expect(result == source)
    }

    @Test func callsWithoutSnapshotsAreLeftAlone() {
        let source = "func test() {\n    other(of: \"x\")\n    assertInline(of: \"y\")\n}"

        let result = Harness.rewrite(source, call: "assertInline", Harness.Snapshot(reference: nil))

        #expect(result.contains("other(of: \"x\")\n"))
        #expect(result.contains("assertInline(of: \"y\") {"))
    }

    // MARK: - Removing the closure

    @Test func aValueThatIsNotTextRemovesTheClosure() {
        let source =
            "func test() {\n    assertInline(of: \"x\") {\n        \"\"\"\n        old\n        \"\"\"\n    }\n}"

        let result = Harness.rewrite(source, Harness.Snapshot(diffable: Data([0xFF, 0xFE])))

        #expect(result == "func test() {\n    assertInline(of: \"x\")\n}")
    }

    // MARK: - Several closures

    @Test func aSecondClosureIsAppendedWhenTheOffsetPointsPastTheExistingOnes() {
        let source = "func test() {\n    assertInline { \"x\" }\n}"
        let descriptor = SnapshotClosureDescriptor(trailingClosureOffset: 1)

        let result = Harness.rewrite(source, Harness.Snapshot(reference: nil, descriptor: descriptor))

        #expect(result.contains("assertInline { \"x\" } matches: {"))
        #expect(result.contains("new"))
    }

    @Test func anExistingLabeledTrailingClosureIsReplaced() {
        let source = """
            func test() {
                assertInline { "x" } matches: {
                    \"\"\"
                    old
                    \"\"\"
                }
            }
            """
        let descriptor = SnapshotClosureDescriptor(trailingClosureOffset: 1)

        let result = Harness.rewrite(source, Harness.Snapshot(descriptor: descriptor))

        #expect(result.contains("matches: {"))
        #expect(result.contains("new"))
        #expect(!result.contains("old"))
    }

    @Test func aDeprecatedLabelIsRenamedToTheCurrentOne() {
        let source = """
            func test() {
                assertInline { "x" } expected: {
                    \"\"\"
                    old
                    \"\"\"
                }
            }
            """
        let descriptor = SnapshotClosureDescriptor(
            deprecatedTrailingClosureLabels: ["expected"],
            trailingClosureOffset: 1
        )

        let result = Harness.rewrite(source, Harness.Snapshot(descriptor: descriptor))

        #expect(result.contains("matches: {"))
        #expect(!result.contains("expected:"))
    }

    @Test func aCustomLabelIsUsed() {
        let source = "func test() {\n    assertInline { \"x\" }\n}"
        let descriptor = SnapshotClosureDescriptor(trailingClosureLabel: "is", trailingClosureOffset: 1)

        let result = Harness.rewrite(source, Harness.Snapshot(reference: nil, descriptor: descriptor))

        #expect(result.contains("} is: {"))
    }

    @Test func callsWithEmptyParenthesesDropThemWhenTheyGetAClosure() {
        let source = "func test() {\n    assertInline()\n}"

        let result = Harness.rewrite(source, Harness.Snapshot(reference: nil))

        #expect(result.contains("assertInline {"))
        #expect(!result.contains("assertInline()"))
    }

    // MARK: - Several calls

    @Test func everyCallInAFileIsRewrittenWithItsOwnValue() {
        let source = "func test() {\n    assertInline(of: \"a\")\n    assertInline(of: \"b\")\n}"

        let result = Harness.rewrite(
            source,
            Harness.Snapshot(reference: nil, diffable: Data("first".utf8), callIndex: 0),
            Harness.Snapshot(reference: nil, diffable: Data("second".utf8), callIndex: 1)
        )

        let first = result.range(of: "first")
        let second = result.range(of: "second")
        #expect(first != nil && second != nil)
        #expect(first!.lowerBound < second!.lowerBound)
    }
}
