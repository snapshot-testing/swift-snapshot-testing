// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation

extension String {

    func indenting(by count: Int) -> String {
        self.indenting(with: String(repeating: " ", count: count))
    }

    func indenting(with prefix: String) -> String {
        guard !prefix.isEmpty else { return self }
        return self.replacingOccurrences(
            of: #"([^\n]+)"#,
            with: "\(prefix)$1",
            options: .regularExpression
        )
    }

    func hashCount(isMultiline: Bool) -> Int {
        let (quote, offset) = isMultiline ? ("\"\"\"", 2) : ("\"", 0)
        var substring = self[...]
        var hashCount = self.escapeHashCount()
        let pattern = "(\(quote)[#]*)"
        while let range = substring.range(of: pattern, options: .regularExpression) {
            let count = substring.distance(from: range.lowerBound, to: range.upperBound) - offset
            hashCount = max(count, hashCount)
            substring = substring[range.upperBound...]
        }
        return hashCount
    }

    /// The delimiter length needed so that no backslash in the text starts an escape or an
    /// interpolation: one more `#` than the longest run that follows a backslash.
    private func escapeHashCount() -> Int {
        var count = 0
        var run: Int?

        for character in self {
            switch character {
            case "\\":
                if let run { count = max(count, run + 1) } else { count = max(count, 1) }
                run = 0
            case "#":
                run = run.map { $0 + 1 }
            default:
                if let run { count = max(count, run + 1) }
                run = nil
            }
        }

        if let run { count = max(count, run + 1) }
        return count
    }
}
