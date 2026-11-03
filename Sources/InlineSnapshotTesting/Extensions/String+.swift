// Copyright (c) Snapshot Testing
// SPDX-License-Identifier: MIT

import Foundation

extension String {

    func indenting(by count: Int) -> String {
        self.indenting(with: String(repeating: " ", count: count))
    }

    func indenting(with prefix: String) -> String {
        guard !prefix.isEmpty else { return self }

        // Walks the scalars: as a `Character`, "\r\n" is one grapheme, and whether string APIs split
        // it at the line feed differs between platforms.
        var result = String.UnicodeScalarView()
        var isAtLineStart = true

        for scalar in self.unicodeScalars {
            if scalar == "\n" {
                isAtLineStart = true
            } else if isAtLineStart {
                result.append(contentsOf: prefix.unicodeScalars)
                isAtLineStart = false
            }
            result.append(scalar)
        }

        return String(result)
    }

    /// Returns the number of `#` that delimit this text as a raw string literal.
    ///
    /// That is one more than the longest run of `#` after a quote in the text, so that the text cannot
    /// close the literal early. A text with a backslash needs at least one, to keep the backslash literal.
    ///
    /// - Parameter isMultiline: Whether the literal uses `"""` instead of `"`.
    func hashCount(isMultiline: Bool) -> Int {
        let quoteLength = isMultiline ? 3 : 1
        // A run of quotes followed by hashes needs a delimiter longer than the hashes: `"""#` needs
        // two, a single `"` followed by `#` needs two as well.
        let overlap = isMultiline ? 2 : 0

        let quote = UInt8(ascii: "\"")
        let hash = UInt8(ascii: "#")

        let bytes = Array(self.utf8)
        var hashCount = self.escapeHashCount()
        var index = 0

        while index + quoteLength <= bytes.count {
            guard bytes[index..<index + quoteLength].allSatisfy({ $0 == quote }) else {
                index += 1
                continue
            }

            var end = index + quoteLength
            while end < bytes.count, bytes[end] == hash {
                end += 1
            }

            hashCount = max(hashCount, end - index - overlap)
            index = end
        }

        return hashCount
    }

    /// The delimiter length needed so that no backslash in the text starts an escape or an
    /// interpolation: one more `#` than the longest run that follows a backslash.
    func escapeHashCount() -> Int {
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
