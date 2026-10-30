// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation
import SnapshotTesting
import Testing
@_spi(Internals) import XCSnapshotTesting

/// The traits are read from the running test, so these checks work on any machine and simulator.
@Suite("Traits")
struct TraitsTests {

    private var environment: SnapshotEnvironment { SnapshotEnvironment.current }

    @Test func withoutTraitsTheDefaultsApply() {
        #expect(environment.recordMode == .missing)
        #expect(environment.maxConcurrentTests == 3)
        #expect(!environment.platform.isEmpty)
    }

    @Test(.record(.failed))
    func theRecordTraitSetsTheRecordMode() {
        #expect(environment.recordMode == .failed)
    }

    @Test(.maxConcurrentTests(2))
    func theMaxConcurrentTestsTraitSetsTheLimit() {
        #expect(environment.maxConcurrentTests == 2)
    }

    @Test(.maxConcurrentTests(0))
    func aLimitBelowOneIsTreatedAsOne() {
        #expect(environment.maxConcurrentTests == 1)
    }

    @Test(.platform("custom-platform"))
    func thePlatformTraitSetsThePlatform() {
        #expect(environment.platform == "custom-platform")
    }

    @Test(.platform(nil))
    func aNilPlatformRemovesThePlatformFromThePath() {
        #expect(environment.platform == "")
    }

    @Test(.diffTool("difftool"))
    func theDiffToolTraitSetsTheTool() {
        #expect(environment.diffTool(currentFilePath: "a", failedFilePath: "b") == "difftool a b")
    }

    @Test(.record(.never), .diffTool(.ksdiff), .maxConcurrentTests(5), .platform("all"))
    func severalTraitsCanBeCombined() {
        #expect(environment.recordMode == .never)
        #expect(environment.maxConcurrentTests == 5)
        #expect(environment.platform == "all")
        #expect(environment.diffTool(currentFilePath: "a", failedFilePath: "b") == "ksdiff \"a\" \"b\"")
    }

    @Suite(.maxConcurrentTests(4), .platform("outer"), .record(.all))
    struct Nested {

        @Test
        func theSuiteTraitsApplyToItsTests() {
            #expect(SnapshotEnvironment.current.maxConcurrentTests == 4)
            #expect(SnapshotEnvironment.current.platform == "outer")
            #expect(SnapshotEnvironment.current.recordMode == .all)
        }

        @Test(.maxConcurrentTests(1), .platform("inner"))
        func theTraitOfATestWinsOverTheTraitOfItsSuite() {
            #expect(SnapshotEnvironment.current.maxConcurrentTests == 1)
            #expect(SnapshotEnvironment.current.platform == "inner")
            #expect(SnapshotEnvironment.current.recordMode == .all, "traits that are not overridden are inherited")
        }

        @Suite(.maxConcurrentTests(6))
        struct Deeper {
            @Test
            func theNearestSuiteWins() {
                #expect(SnapshotEnvironment.current.maxConcurrentTests == 6)
                #expect(SnapshotEnvironment.current.platform == "outer")
            }
        }
    }
}
