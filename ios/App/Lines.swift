// Line math for the gutter, Go to Line and the outline. Pure Foundation, no UI.
// Offsets are UTF-16, because that is what UITextView and NSRange speak.
// Lines are numbered from 1 and a trailing newline starts one more (empty) line, the way a caret sees it.

import Foundation

struct LineIndex: Equatable {
    /// UTF-16 offset where each line starts. Always at least one entry.
    private(set) var starts: [Int] = [0]
    private(set) var length = 0

    init(_ text: String) {
        var offset = 0
        for u in text.utf16 {
            offset += 1
            if u == 10 { starts.append(offset) }
        }
        length = offset
    }

    var count: Int { starts.count }

    /// The 1-based line holding a UTF-16 offset. Offsets past the end land on the last line.
    func line(at offset: Int) -> Int {
        let o = min(max(offset, 0), length)
        var lo = 0, hi = starts.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if starts[mid] <= o { lo = mid } else { hi = mid - 1 }
        }
        return lo + 1
    }

    /// Start offset of a 1-based line, clamped into the document.
    func offset(ofLine line: Int) -> Int { starts[min(max(line, 1), count) - 1] }

    /// Parses what someone typed into Go to Line. Nil for anything that is not a positive whole number.
    static func parse(_ input: String) -> Int? {
        guard let n = Int(input.trimmingCharacters(in: .whitespaces)), n > 0 else { return nil }
        return n
    }
}

extension Regex.Match where Output == AnyRegexOutput {
    /// Capture group `i` as a String ("" if it did not take part). Runtime regexes have no typed captures.
    func group(_ i: Int) -> String { output[i].substring.map(String.init) ?? "" }
}
