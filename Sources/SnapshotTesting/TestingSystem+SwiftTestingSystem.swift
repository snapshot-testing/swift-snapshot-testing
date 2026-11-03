// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

extension TestingSystem: @retroactive SwiftTestingSystem {

    /// The overrides set by the traits of the running test, or `nil` outside of a test.
    public var environment: TestingSystemEnvironment? {
        Test.current?.traits.mapIntoTestingEnvironment()
    }

    /// Whether code is running inside a Swift Testing test.
    public var isRunning: Bool {
        Test.current != nil
    }

    /// Whether the running test belongs to a suite that applies the `finalizeSnapshots` trait.
    public var isTestCompletionAttached: Bool {
        isRunning && TestCompletionNotifier.current != nil
    }

    /// Attaches each attachment that has a payload to the running test.
    ///
    /// Swift Testing has no activities, so `name` is not used.
    public func add(
        _ name: String,
        attachments: [SnapshotAttachment],
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        for attachment in attachments {
            guard let payload = attachment.payload else {
                continue
            }

            let attachmentName: String
            if let name = attachment.name, !name.isEmpty {
                attachmentName = name
            } else {
                attachmentName = attachment.uniformTypeIdentifier
            }

            Attachment.record(
                Array(payload),
                named: attachmentName,
                sourceLocation: SourceLocation(
                    fileID: String(describing: fileID),
                    filePath: String(describing: filePath),
                    line: max(1, Int(clamping: line)),
                    column: max(1, Int(clamping: column))
                )
            )
        }
    }

    /// Records `message` as an issue on the running test.
    public func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        Issue.record(
            Comment(rawValue: message),
            sourceLocation: SourceLocation(
                fileID: String(describing: fileID),
                filePath: String(describing: filePath),
                line: max(1, Int(clamping: line)),
                column: max(1, Int(clamping: column))
            )
        )
    }
}

extension Array where Element == any Trait {

    /// Merges the snapshot traits into one environment.
    ///
    /// The traits are read in reverse order, and the first value found for each setting is kept.
    func mapIntoTestingEnvironment() -> TestingSystemEnvironment {
        var environment = TestingSystemEnvironment()

        for trait in reversed() {
            switch trait {
            case let recordTrait as RecordTrait:
                if environment.recordMode == nil {
                    environment.recordMode = recordTrait.recordMode
                }
            case let diffToolTrait as DiffToolTrait:
                if environment.diffTool == nil {
                    environment.diffTool = diffToolTrait.diffTool
                }
            case let maxConcurrentTestsTrait as MaxConcurrentTestsTrait:
                if environment.maxConcurrentTests == nil {
                    environment.maxConcurrentTests = maxConcurrentTestsTrait.maxConcurrentTests
                }
            case let platformTrait as PlatformTrait:
                if environment.platform == nil {
                    environment.platform = platformTrait.platform
                }
            default:
                continue
            }

            guard
                environment.diffTool != nil,
                environment.recordMode != nil,
                environment.maxConcurrentTests != nil,
                environment.platform != nil
            else { continue }

            break
        }

        return environment
    }
}
#endif
