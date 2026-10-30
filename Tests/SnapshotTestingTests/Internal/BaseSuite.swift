// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

#if canImport(Testing)
import Testing
import SnapshotTesting

@Suite(.record(.failed), .diffTool(.ksdiff), .platform(nil))
struct BaseSuite {
}
#endif
