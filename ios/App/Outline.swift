// Headings for Markdown, top-level symbols for code. Same regex style as Highlight.swift.
// ponytail: one symbol pattern for every language, no parser. A keyword inside a multi-line string can
// show up; real grammars only if that turns out to matter.

import Foundation
import UniformTypeIdentifiers

struct OutlineItem: Equatable, Identifiable {
    var line: Int        // 1-based
    var level: Int       // 0 is outermost
    var title: String
    var id: Int { line }
}

enum Outline {
    private static let heading = try! Regex(#"^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$"#)
    private static let fence = try! Regex(#"^[ \t]*(?:```|~~~)"#)
    private static let symbol = try! Regex(#"^([ \t]*)(?:(?:public|private|internal|fileprivate|open|static|final|override|export|default|async|pub|abstract)[ \t]+)*(func|class|struct|enum|protocol|extension|actor|def|function|fn|interface|trait|impl|mod|type)[ \t]+([A-Za-z_$][\w$]*)"#)

    static func items(in text: String, kind: Kind) -> [OutlineItem] {
        switch kind {
        case .markdown: return markdown(text)
        case .code: return code(text)
        case .text: return []
        }
    }

    private static func markdown(_ text: String) -> [OutlineItem] {
        var out: [OutlineItem] = []
        var inFence = false
        for (i, raw) in text.components(separatedBy: "\n").enumerated() {
            let line = String(raw).trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            if line.prefixMatch(of: fence) != nil { inFence.toggle(); continue }
            if inFence { continue }
            guard let m = line.wholeMatch(of: heading) else { continue }
            out.append(OutlineItem(line: i + 1, level: m.group(1).count - 1, title: m.group(2)))
        }
        return out
    }

    private static func code(_ text: String) -> [OutlineItem] {
        var out: [OutlineItem] = []
        for (i, raw) in text.components(separatedBy: "\n").enumerated() {
            guard let m = String(raw).prefixMatch(of: symbol) else { continue }
            let nested = !m.group(1).isEmpty
            out.append(OutlineItem(line: i + 1, level: nested ? 1 : 0, title: "\(m.group(2)) \(m.group(3))"))
        }
        return out
    }
}
