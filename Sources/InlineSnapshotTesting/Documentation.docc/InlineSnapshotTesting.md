# ``InlineSnapshotTesting``

Powerfully convenient snapshot testing.

## Overview

[Snapshot Testing][swift-snapshot-testing] writes the snapshots it generates to files next to the
test files. This makes for compact test cases with single line assertions...

```swift
try await assert(of: value, as: .json)
```

...but verifying a snapshot means finding the corresponding file.

Inline Snapshot Testing writes string snapshots directly into the test file, so the value and the
snapshot sit next to each other. `import InlineSnapshotTesting` and rewrite the assertion as:

```swift
try assertInline(of: value, as: .json)
```

When the test runs, it inserts the snapshot as a trailing closure and fails:

```swift
try assertInline(of: value, as: .json) {  // ❌
  """
  {
    "id": 42,
    "name": "Blob"
  }
  """
}
```

```
❌ failed - Automatically recorded a new snapshot.

Re-run "testMySnapshot" to test against the newly-recorded snapshot.
```

The closure is the reference. A later run compares the value with it, and `record:` decides whether
a mismatch rewrites it.

### Swift Testing and XCTest

Under XCTest the files are written when the test bundle finishes. Under Swift Testing they are
written when the suite ends, so the suite needs the `.finalizeSnapshots` trait from
`SnapshotTesting`; `assertInline` throws an error that says so when it is missing.

```swift
@Suite(.finalizeSnapshots)
struct InlineTests { … }
```

The file is written from the version that was read when its first assertion ran. If the file
changes on disk before it is written, for example because you saved it in the editor, it is left
alone and the failure message says so.

> Warning: When a snapshot is written into a test file, the undo history of the test file in Xcode
> will be lost. Be careful to avoid losing work, and commit often to version control.

[swift-snapshot-testing]: https://github.com/snapshot-testing/swift-snapshot-testing

## Topics

### Essentials

- ``assertInline(of:as:message:record:timeout:name:serialization:closureDescriptor:matches:fileID:file:function:line:column:)``

### Writing a custom helper

- ``SnapshotClosureDescriptor``
