# ``SnapshotTesting``

Snapshot testing for Swift Testing, with the same assertions working in XCTest.

## Overview

SnapshotTesting re-exports `XCSnapshotTesting`, which provides the assertions (`assert(of:as:)`)
and the snapshot strategies (`.image`, `.lines`, `.json`, `.customDump` and more), and adds the
Swift Testing traits that configure them.

```swift
import SnapshotTesting
import Testing

@Suite(.record(.missing), .diffTool(.ksdiff))
struct FeatureTests {

    @Test
    func rendersTheFeature() async throws {
        try await assert(of: FeatureView(), as: .image)
    }
}
```

## Topics

### Essentials

- <doc:IntegratingWithTestFrameworks>
- <doc:CustomStrategies>

### Configuring tests

- ``RecordTrait``
- ``DiffToolTrait``
- ``MaxConcurrentTestsTrait``
- ``PlatformTrait``

### Inline snapshots

- ``FinalizeSnapshotsSuiteTrait``
