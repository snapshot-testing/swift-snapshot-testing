# Integrating with test frameworks

Use the same assertions in Swift Testing and in XCTest.

## Overview

`assert(of:as:)` reports a failure to whichever framework is running the test: through
`Issue.record` in a Swift Testing `@Test`, and through `XCTFail` in an `XCTestCase`. A failure in
one framework is not seen by the other, so the library picks the right one when the assertion runs.

```swift
@Test
func feature() async throws {
    try await assert(of: FeatureView(), as: .image)
}

final class FeatureTests: XCTestCase {
    func testFeature() async throws {
        try await assert(of: FeatureView(), as: .image)
    }
}
```

### Configuring snapshots in Swift Testing

Four traits configure the assertions of a test or of a whole suite. They are recursive, so a trait
on a suite applies to every test inside it, and the closest one wins:

| Trait | Effect |
| --- | --- |
| `.record(_:)` | When references are written: `.missing` (the default), `.failed`, `.all` or `.never`. |
| `.diffTool(_:)` | The command printed in a failure message to open a diff, such as `.ksdiff`. |
| `.maxConcurrentTests(_:)` | How many snapshots may use a window at the same time. A value below one counts as one. |
| `.platform(_:)` | A platform name added to the reference path; `nil` or an empty string shares references between platforms. |

```swift
@Suite(.record(.failed), .diffTool(.ksdiff))
struct FeatureTests {
    …
}
```

### Configuring snapshots in XCTest

XCTest has no traits. Wrap the test in `withTestingEnvironment` by overriding `invokeTest`:

```swift
final class FeatureTests: XCTestCase {
    override func invokeTest() {
        withTestingEnvironment(record: .failed, diffTool: .ksdiff) {
            super.invokeTest()
        }
    }
}
```

### Inline snapshots

`assertInline` from `InlineSnapshotTesting` writes the snapshot into the test file. Under Swift
Testing the file is written when the suite ends, so the suite needs the `.finalizeSnapshots` trait.
Without it, `assertInline` throws an error telling you to add it instead of recording anything.

```swift
@Suite(.finalizeSnapshots)
struct InlineTests { … }
```

Under XCTest the files are written when the test bundle finishes and no trait is needed.

### UI test targets

Xcode compiles UI test targets with `-module_alias Testing=_Testing_Unavailable`, so
`import Testing` fails there. To use SnapshotTesting in a UI test target, remove that flag by
deleting `$(inherited)` from the target's "Other Swift Flags". Swift Testing's own macros, such as
`#expect`, stay unavailable in that target.
