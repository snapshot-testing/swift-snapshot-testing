import Foundation
import Testing

@testable import InlineSnapshotTesting

@Suite("Snapshot visitor")
struct SnapshotVisitorTests {

    private typealias Harness = RewriterHarness

    @Test func reportsTheLineOfTheTrailingClosure() {
        let source =
            "func test() {\n    assertInline(of: \"x\") {\n        \"\"\"\n        old\n        \"\"\"\n    }\n}"

        #expect(Harness.trailingClosureLine(in: source) == 2)
    }

    @Test func reportsTheLineOfALabeledClosureArgument() {
        let source =
            "func test() {\n    assertInline(\n        of: \"x\",\n        matches: {\n            \"\"\"\n            old\n            \"\"\"\n        }\n    )\n}"

        #expect(Harness.trailingClosureLine(in: source) == 4)
    }

    @Test func reportsTheLineOfAnAdditionalTrailingClosure() {
        let source =
            "func test() {\n    assertInline { \"x\" }\n    matches: {\n        \"\"\"\n        old\n        \"\"\"\n    }\n}"
        let descriptor = SnapshotClosureDescriptor(trailingClosureOffset: 1)

        #expect(Harness.trailingClosureLine(in: source, descriptor: descriptor) == 3)
    }

    @Test func reportsNothingWhenThereIsNoClosureAtTheOffset() {
        let source = "func test() {\n    assertInline(of: \"x\")\n}"

        #expect(Harness.trailingClosureLine(in: source) == nil)
    }

    @Test func descriptorsMatchTheirCurrentAndDeprecatedLabels() {
        let descriptor = SnapshotClosureDescriptor(deprecatedTrailingClosureLabels: ["expected", "is"])

        #expect(SnapshotClosureDescriptor.defaultTrailingClosureLabel == "matches")
        #expect(descriptor.contains("matches"))
        #expect(descriptor.contains("expected"))
        #expect(descriptor.contains("is"))
        #expect(!descriptor.contains("other"))
    }
}
