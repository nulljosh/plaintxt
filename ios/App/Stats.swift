// The one piece of logic the app and the CLI share. Pure Foundation, no UI.

import Foundation

struct Stats: Equatable {
    var lines: Int
    var words: Int
    var characters: Int   // grapheme clusters, so "🍋‍🟩" counts as 1, not 5

    init(_ text: String) {
        // An empty document has one (empty) line, not zero. A trailing newline does not add one.
        var l = 1
        for c in text where c == "\n" { l += 1 }
        if text.hasSuffix("\n") { l -= 1 }
        lines = l
        words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        characters = text.count
    }

    var summary: String { "\(lines) \(lines == 1 ? "line" : "lines"), \(words) \(words == 1 ? "word" : "words"), \(characters) \(characters == 1 ? "char" : "chars")" }
}

extension Stats {
    init(lines: Int, words: Int, characters: Int) { self.lines = lines; self.words = words; self.characters = characters }
}
