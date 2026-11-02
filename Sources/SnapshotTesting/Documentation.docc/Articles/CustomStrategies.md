# Defining custom snapshot strategies

Describe how a value becomes the bytes that are saved and compared.

## Overview

A strategy is a `Snapshot` value. It has three parts:

- the file extension used to save the reference (`pathExtension`),
- an attachment generator that compares a reference with a new value and describes the difference
  (`.lines` compares text line by line),
- an executor that turns the input into the output that is saved.

The output type conforms to `BytesRepresentable`; `StringBytes` stores text and `DataBytes` stores
raw data.

### Synchronous strategies

The executor receives the input and a continuation to resume with the output (or an error):

```swift
let uppercased = SyncSnapshot<String, StringBytes>(
    pathExtension: "txt",
    attachmentGenerator: .lines,
    executor: Sync { input, continuation in
        continuation.resume(returning: StringBytes(rawValue: input.uppercased()))
    }
)

try assert(of: "value", as: uppercased)
```

### Asynchronous strategies

Use `Async` when the output needs `await`:

```swift
let snapshot = AsyncSnapshot<String, StringBytes>(
    pathExtension: "txt",
    attachmentGenerator: .lines,
    executor: Async { input in
        try await Task.sleep(nanoseconds: 100_000_000)
        return StringBytes(rawValue: input)
    }
)

try await assert(of: "value", as: snapshot)
```

### Timeouts

Both kinds of assertion take a `timeout` in seconds. The asynchronous `assert` has no timeout by
default (zero); the synchronous one defaults to five seconds. When the time runs out, the assertion
fails with a message that says how long it waited.
