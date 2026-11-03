# ``SnapshotTesting``

Configure snapshot tests with Swift Testing traits.

## Overview

`SnapshotTesting` connects [XCSnapshotTesting](https://github.com/snapshot-testing/xc-snapshot-testing)
to Swift Testing. It re-exports that module, so `assert(of:as:)` and the snapshot strategies are
available after a single import, and it adds traits that set the record mode, the diff tool, the
platform and the rendering concurrency for a test or a whole suite.

```swift
import SnapshotTesting
import Testing

@Suite(.diffTool(.ksdiff))
struct ProfileTests {

    @Test(.record(.all))
    func profileView() async throws {
        try await assert(of: ProfileView(), as: .image)
    }
}
```

Failures and attachments go to Swift Testing when a Swift Testing test is running, and to XCTest
otherwise, so the same assertion works in both.

The API of XCSnapshotTesting is listed below as well, because this module re-exports it. Its own
documentation has the same content.

## Topics

### Essentials

- <doc:IntegratingWithTestFrameworks>
- <doc:CustomStrategies>

### Traits

- ``RecordTrait``
- ``DiffToolTrait``
- ``PlatformTrait``
- ``MaxConcurrentTestsTrait``
- ``FinalizeSnapshotsSuiteTrait``

### Asserting

- ``assert(of:as:serialization:named:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)``
- ``assert(of:as:serialization:named:record:snapshotDirectory:timeout:isolation:fileID:file:testName:line:column:)``
- ``verify(of:as:serialization:named:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)``
- ``verify(of:as:serialization:named:record:snapshotDirectory:timeout:isolation:fileID:file:testName:line:column:)``
- ``assert(of:as:serialization:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)-97yat``
- ``assert(of:as:serialization:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)-8jkj5``
- ``assert(of:as:serialization:record:snapshotDirectory:timeout:isolation:fileID:file:testName:line:column:)-928gi``
- ``assert(of:as:serialization:record:snapshotDirectory:timeout:isolation:fileID:file:testName:line:column:)-1hd5i``
- ``RecordMode``
- ``TaskTimeout``

### Defining a snapshot strategy

- ``Snapshot``
- ``SnapshotExecutor``
- ``Sync``
- ``Async``
- ``SyncSnapshot``
- ``AsyncSnapshot``
- ``IdentitySyncSnapshot``
- ``IdentityAsyncSnapshot``
- ``SyncContinuation``

### Serializing snapshots

- ``BytesRepresentable``
- ``BytesContainer``
- ``BytesSerializationError``
- ``DataSerialization``
- ``DataSerializationConfiguration``
- ``DataSerializationConfigurationKey``
- ``DataBytes``
- ``StringBytes``
- ``ImageBytes``
- ``ImageFormat``

### Reporting differences

- ``DiffAttachmentGenerator``
- ``DiffAttachment``
- ``DataDiffAttachmentGenerator``
- ``StringDiffAttachmentGenerator``
- ``ImageDiffAttachmentGenerator``
- ``DiffTool``
- ``SnapshotAttachment``

### Configuring the environment

- ``SnapshotEnvironment``
- ``SnapshotEnvironmentValues``
- ``SnapshotEnvironmentKey``
- ``withTestingEnvironment(_:operation:file:line:)-7a0j4``
- ``withTestingEnvironment(_:operation:file:line:)-6chs6``
- ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)-9dns4``
- ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)-8wyqi``
- ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:environment:operation:file:line:)-3trzi``
- ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:environment:operation:file:line:)-9j11c``

### Rendering views

- ``SnapshotLayout``
- ``LayoutConfiguration``
- ``DeviceOrientation``
- ``DeviceLayoutRatio``
- ``Traits``
- ``InterfaceSizeClass``
- ``DeviceInterfaceSizeClass``
- ``DeviceDynamicInterfaceSizeClass``
