// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

struct SnapshotURL: Sendable, Hashable {

    let path: StaticString

    /// The path as a string, built once because it is compared and hashed on every assertion.
    private let string: String

    init(path: StaticString) {
        self.path = path
        self.string = String(describing: path)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.string == rhs.string
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(string)
    }
}
