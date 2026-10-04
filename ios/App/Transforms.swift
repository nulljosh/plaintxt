import Foundation

/// One-tap text clean-ups for the whole document. Pure string functions, shared by iOS and macOS.
enum TextTool: String, CaseIterable, Identifiable {
    case sortLines, uniqueLines, reverseLines, trimTrailing, uppercase, lowercase, titleCase, tabsToSpaces, spacesToTabs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sortLines: "Sort Lines"
        case .uniqueLines: "Remove Duplicate Lines"
        case .reverseLines: "Reverse Lines"
        case .trimTrailing: "Trim Trailing Spaces"
        case .uppercase: "UPPERCASE"
        case .lowercase: "lowercase"
        case .titleCase: "Title Case"
        case .tabsToSpaces: "Tabs to Spaces"
        case .spacesToTabs: "Spaces to Tabs"
        }
    }

    var icon: String {
        switch self {
        case .sortLines: "arrow.up.arrow.down"
        case .uniqueLines: "rectangle.stack.badge.minus"
        case .reverseLines: "arrow.uturn.up"
        case .trimTrailing: "scissors"
        case .uppercase, .lowercase, .titleCase: "textformat.abc"
        case .tabsToSpaces, .spacesToTabs: "arrow.left.and.right"
        }
    }

    func apply(_ s: String) -> String {
        switch self {
        case .sortLines: return mapLines(s) { $0.sorted { $0.localizedStandardCompare($1) == .orderedAscending } }
        case .uniqueLines:
            return mapLines(s) { lines in var seen = Set<String>(); return lines.filter { seen.insert($0).inserted } }
        case .reverseLines: return mapLines(s) { $0.reversed() }
        case .trimTrailing: return mapLines(s) { $0.map { line in String(line.reversed().drop { $0 == " " || $0 == "\t" }.reversed()) } }
        case .uppercase: return s.uppercased()
        case .lowercase: return s.lowercased()
        case .titleCase: return s.capitalized
        case .tabsToSpaces: return s.replacingOccurrences(of: "\t", with: "    ")
        case .spacesToTabs: return s.replacingOccurrences(of: "    ", with: "\t")
        }
    }

    /// Applies `f` to the lines and keeps a trailing newline if the text had one.
    private func mapLines(_ s: String, _ f: ([String]) -> [String]) -> String {
        let endsWithNewline = s.hasSuffix("\n")
        var lines = s.components(separatedBy: "\n")
        if endsWithNewline { lines.removeLast() }
        return f(lines).joined(separator: "\n") + (endsWithNewline ? "\n" : "")
    }
}
