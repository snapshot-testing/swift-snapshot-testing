// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
@_spi(Internals) import XCSnapshotTesting
#if canImport(Testing)
@_spi(Internals) import SnapshotTesting
#endif

/// Waits for the end of the test run to write the pending inline snapshots.
final class SnapshotInlineObservation: @unchecked Sendable {

    static let shared = SnapshotInlineObservation()

    private let lock = NSLock()

    private var _isObserving = false
    private var _xcObserver: NSObjectProtocol?
    private var _swiftTestingObserver: NSObjectProtocol?

    /// Starts observing, if it is not observing yet.
    ///
    /// When the XCTest bundle finishes, the snapshots of every file are written. When a Swift Testing
    /// suite finishes, only the snapshots of the file named in the notification are written.
    func registerIfNeeded() {
        lock.withLock {
            guard !_isObserving else {
                return
            }

            _isObserving = true

            _xcObserver = NotificationCenter.default.addObserver(
                forName: XCTestBundleDidFinishNotification,
                object: nil,
                queue: nil,
                using: { [weak self] in self?.xcTestDidFinish($0) }
            )

            _swiftTestingObserver = NotificationCenter.default.addObserver(
                forName: SwiftTestingDidFinishNotification,
                object: nil,
                queue: nil,
                using: { [weak self] in self?.swiftTestDidFinish($0) }
            )
        }
    }

    private func xcTestDidFinish(_ notification: Notification) {
        InlineSnapshotManager.current.writeInlineSnapshots()
    }

    private func swiftTestDidFinish(_ notification: Notification) {
        #if canImport(Testing)
        guard let scope = notification.userInfo?[kTestScopeID] as? UUID else {
            return
        }

        InlineSnapshotManager.current.writeInlineSnapshots(scope: scope)
        #endif
    }
}
