// Read-only Markdown preview. The text is split into blocks by hand (AttributedString only does the
// inline part: emphasis, code spans, links), so headings, lists and quotes render on every OS.
// A line AttributedString cannot parse falls back to plain text. Nothing here ever touches the document.

import SwiftUI

enum MDBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullet(indent: Int, text: String)
    case numbered(indent: Int, number: String, text: String)
    case quote(String)
    case code(String)
    case rule
}

enum MarkdownPreview {
    private static let headingRe = try! Regex(#"^(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$"#)
    private static let bulletRe = try! Regex(#"^([ \t]*)[-*+][ \t]+(.*)$"#)
    private static let numberedRe = try! Regex(#"^([ \t]*)(\d+)[.)][ \t]+(.*)$"#)
    private static let ruleRe = try! Regex(#"^[ \t]*(?:-{3,}|\*{3,}|_{3,})[ \t]*$"#)
    private static let quoteRe = try! Regex(#"^[ \t]*>[ \t]?(.*)$"#)
    private static let fenceRe = try! Regex(#"^[ \t]*(?:```|~~~)"#)

    static func blocks(_ text: String) -> [MDBlock] {
        var out: [MDBlock] = []
        var para: [String] = []
        var codeLines: [String] = []
        var inFence = false
        func flush() { if !para.isEmpty { out.append(.paragraph(para.joined(separator: " "))); para = [] } }
        for raw in text.components(separatedBy: "\n") {
            let line = String(raw).trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            if line.prefixMatch(of: fenceRe) != nil {
                if inFence { out.append(.code(codeLines.joined(separator: "\n"))); codeLines = [] } else { flush() }
                inFence.toggle(); continue
            }
            if inFence { codeLines.append(line); continue }
            if line.trimmingCharacters(in: .whitespaces).isEmpty { flush(); continue }
            if let m = line.wholeMatch(of: headingRe) { flush(); out.append(.heading(level: m.group(1).count, text: m.group(2))) }
            else if line.wholeMatch(of: ruleRe) != nil { flush(); out.append(.rule) }
            else if let m = line.wholeMatch(of: bulletRe) { flush(); out.append(.bullet(indent: m.group(1).count / 2, text: m.group(2))) }
            else if let m = line.wholeMatch(of: numberedRe) { flush(); out.append(.numbered(indent: m.group(1).count / 2, number: m.group(2), text: m.group(3))) }
            else if let m = line.wholeMatch(of: quoteRe) { flush(); out.append(.quote(m.group(1))) }
            else { para.append(line.trimmingCharacters(in: .whitespaces)) }
        }
        if inFence { out.append(.code(codeLines.joined(separator: "\n"))) }   // unterminated fence still shows
        flush()
        return out
    }

    /// Inline Markdown to styled text; plain text if it will not parse.
    static func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}

struct MarkdownPreviewView: View {
    let text: String
    var size: Double

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: size * 0.6) {
                ForEach(Array(MarkdownPreview.blocks(text).enumerated()), id: \.offset) { _, b in row(b) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .accessibilityIdentifier("markdownPreview")
    }

    @ViewBuilder private func row(_ b: MDBlock) -> some View {
        switch b {
        case .heading(let level, let t):
            Text(MarkdownPreview.inline(t))
                .font(.system(size: size * [1.9, 1.6, 1.35, 1.2, 1.1, 1.0][level - 1], weight: .bold))
                .padding(.top, level <= 2 ? size * 0.4 : 0)
        case .paragraph(let t): Text(MarkdownPreview.inline(t)).font(.system(size: size))
        case .bullet(let indent, let t): item("\u{2022}", t, indent)
        case .numbered(let indent, let n, let t): item("\(n).", t, indent)
        case .quote(let t):
            Text(MarkdownPreview.inline(t)).font(.system(size: size)).foregroundStyle(.secondary)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(.tertiary).frame(width: 3) }
        case .code(let t):
            Text(t).font(.system(size: size * 0.9, design: .monospaced)).textSelection(.enabled)
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        case .rule: Divider()
        }
    }

    private func item(_ marker: String, _ t: String, _ indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(marker).font(.system(size: size)).foregroundStyle(.secondary)
            Text(MarkdownPreview.inline(t)).font(.system(size: size))
        }
        .padding(.leading, CGFloat(indent) * 18)
    }
}
