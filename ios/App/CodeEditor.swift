// iOS editor: a UITextView wrapped for SwiftUI, because a gutter, Go to Line and jump-to-symbol need a
// text view you can ask where a line is. It edits the same String the DocumentGroup owns; TextDocument
// is untouched. Colour comes from Highlighter.spans, drawn as attributes. Find and Replace is the
// system one (UIFindInteraction). Mac keeps its TextEditor.

#if os(iOS)
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Lets SwiftUI ask the wrapped text view to do things: open Find, jump to a line.
final class EditorController: ObservableObject {
    fileprivate weak var textView: UITextView?

    func find() { textView?.findInteraction?.presentFindNavigator(showingReplace: true) }

    /// Puts the caret at the start of a 1-based line and scrolls it near the top. Returns the line used.
    @discardableResult
    func goTo(line: Int) -> Int {
        guard let tv = textView else { return line }
        let index = LineIndex(tv.text)
        let target = min(max(line, 1), index.count)
        let range = NSRange(location: index.offset(ofLine: target), length: 0)
        tv.becomeFirstResponder()
        tv.selectedRange = range
        let lm = tv.layoutManager
        lm.ensureLayout(forCharacterRange: NSRange(location: 0, length: min(range.location + 1, (tv.text as NSString).length)))
        let glyph = lm.glyphIndexForCharacter(at: min(range.location, max((tv.text as NSString).length - 1, 0)))
        var y = tv.textContainerInset.top
        if (tv.text as NSString).length > 0, range.location < (tv.text as NSString).length {
            y += lm.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil).minY
        } else {
            y += lm.extraLineFragmentRect.minY
        }
        let maxY = max(tv.contentSize.height - tv.bounds.height + tv.adjustedContentInset.bottom, -tv.adjustedContentInset.top)
        tv.setContentOffset(CGPoint(x: 0, y: min(max(y - 12 - tv.adjustedContentInset.top, -tv.adjustedContentInset.top), maxY)), animated: true)
        return target
    }
}

struct CodeEditor: UIViewRepresentable {
    @Binding var text: String
    var type: UTType
    var size: Double
    var monospaced: Bool
    var showLineNumbers: Bool
    var controller: EditorController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> EditorContainer {
        let c = EditorContainer()
        let tv = c.textView
        tv.delegate = context.coordinator
        tv.isFindInteractionEnabled = true
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.keyboardDismissMode = .interactive
        tv.alwaysBounceVertical = true
        tv.backgroundColor = .clear
        tv.accessibilityIdentifier = "editor"
        controller.textView = tv
        tv.text = text
        context.coordinator.restyle(tv, parent: self)
        c.update(lineNumbers: showLineNumbers, lines: LineIndex(text), size: size, monospaced: monospaced)
        return c
    }

    func updateUIView(_ c: EditorContainer, context: Context) {
        context.coordinator.parent = self
        controller.textView = c.textView
        let tv = c.textView
        var changed = false
        if tv.text != text {   // undo, revert, iCloud, a Text Tool
            let sel = tv.selectedRange
            tv.text = text
            tv.selectedRange = NSRange(location: min(sel.location, (text as NSString).length), length: 0)
            changed = true
        }
        let key = "\(type.identifier)|\(size)|\(monospaced)"
        if changed || context.coordinator.styleKey != key { context.coordinator.styleKey = key; context.coordinator.restyle(tv, parent: self) }
        c.update(lineNumbers: showLineNumbers, lines: LineIndex(text), size: size, monospaced: monospaced)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditor
        var styleKey = ""
        init(_ p: CodeEditor) { parent = p }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            if tv.markedTextRange == nil { restyle(tv, parent: parent) }
            (tv.superview as? EditorContainer)?.update(lineNumbers: parent.showLineNumbers, lines: LineIndex(tv.text), size: parent.size, monospaced: parent.monospaced)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) { (scrollView.superview as? EditorContainer)?.gutter.setNeedsDisplay() }

        func restyle(_ tv: UITextView, parent p: CodeEditor) {
            let s = tv.text ?? ""
            let full = NSRange(location: 0, length: (s as NSString).length)
            let para = NSMutableParagraphStyle()
            para.lineSpacing = p.size * 0.25
            let base = EditorContainer.font(p.size, monospaced: p.monospaced)
            let attrs: [NSAttributedString.Key: Any] = [.font: base, .foregroundColor: UIColor.label, .paragraphStyle: para]
            let sel = tv.selectedRange
            let st = tv.textStorage
            st.beginEditing()
            st.setAttributes(attrs, range: full)
            for span in Highlighter(type: p.type, size: p.size, monospaced: p.monospaced).spans(s) {
                let r = NSRange(span.range, in: s)
                if let c = span.color { st.addAttribute(.foregroundColor, value: UIColor(c), range: r) }
                switch span.face {
                case .italic: st.addAttribute(.font, value: EditorContainer.trait(base, .traitItalic), range: r)
                case .bold: st.addAttribute(.font, value: EditorContainer.trait(base, .traitBold), range: r)
                case .code: st.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: p.size, weight: .regular), range: r)
                case nil: break
                }
            }
            st.endEditing()
            tv.typingAttributes = attrs
            if tv.selectedRange != sel { tv.selectedRange = sel }
        }
    }
}

/// Gutter on the left, text view on the right. The gutter draws from the text view's own layout, so a wrapped
/// line gets one number and the numbers cannot drift from the text.
final class EditorContainer: UIView {
    let textView = UITextView(usingTextLayoutManager: false)
    let gutter = GutterView()
    private var gutterWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        gutter.textView = textView
        addSubview(textView)
        addSubview(gutter)
        gutter.isOpaque = false
        gutter.isUserInteractionEnabled = false
        gutter.accessibilityIdentifier = "lineNumbers"
    }
    required init?(coder: NSCoder) { fatalError() }

    static func font(_ size: Double, monospaced: Bool) -> UIFont {
        monospaced ? .monospacedSystemFont(ofSize: size, weight: .regular) : .systemFont(ofSize: size)
    }
    static func trait(_ f: UIFont, _ t: UIFontDescriptor.SymbolicTraits) -> UIFont {
        f.fontDescriptor.withSymbolicTraits(t).map { UIFont(descriptor: $0, size: f.pointSize) } ?? f
    }

    func update(lineNumbers: Bool, lines: LineIndex, size: Double, monospaced: Bool) {
        gutter.lines = lines
        gutter.baseFont = Self.font(size, monospaced: monospaced)
        gutter.numberFont = .monospacedDigitSystemFont(ofSize: max(9, size * 0.8), weight: .regular)
        gutter.isHidden = !lineNumbers
        let digits = max(2, String(lines.count).count)
        let w = lineNumbers ? ceil(CGFloat(digits) * gutter.numberFont.pointSize * 0.62) + 18 : 0
        if w != gutterWidth { gutterWidth = w; setNeedsLayout() }
        let left: CGFloat = lineNumbers ? 8 : 16
        if textView.textContainerInset.left != left { textView.textContainerInset = UIEdgeInsets(top: 8, left: left, bottom: 8, right: 16) }
        gutter.setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gutter.frame = CGRect(x: 0, y: 0, width: gutterWidth, height: bounds.height)
        textView.frame = CGRect(x: gutterWidth, y: 0, width: bounds.width - gutterWidth, height: bounds.height)
        gutter.setNeedsDisplay()
    }
}

final class GutterView: UIView {
    weak var textView: UITextView?
    var lines = LineIndex("")
    var baseFont = UIFont.systemFont(ofSize: 15)
    var numberFont = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)

    override func draw(_ rect: CGRect) {
        guard let tv = textView, !isHidden else { return }
        UIColor.separator.setFill()
        UIRectFill(CGRect(x: bounds.width - 0.5, y: 0, width: 0.5, height: bounds.height))
        let lm = tv.layoutManager
        let text = tv.text as NSString
        let top = tv.textContainerInset.top - tv.contentOffset.y   // text-container y 0 sits here in gutter space
        let para = NSMutableParagraphStyle(); para.alignment = .right
        let attrs: [NSAttributedString.Key: Any] = [.font: numberFont, .foregroundColor: UIColor.tertiaryLabel]
        func draw(_ n: Int, baseline: CGFloat) {
            ("\(n)" as NSString).draw(in: CGRect(x: 0, y: baseline - numberFont.ascender, width: bounds.width - 8, height: numberFont.lineHeight),
                                      withAttributes: attrs.merging([.paragraphStyle: para]) { $1 })
        }
        let visible = CGRect(x: 0, y: -top, width: tv.bounds.width, height: bounds.height)
        let glyphs = lm.glyphRange(forBoundingRect: visible, in: tv.textContainer)
        lm.enumerateLineFragments(forGlyphRange: glyphs) { rect, _, _, glyphRange, _ in
            let loc = lm.characterIndexForGlyph(at: glyphRange.location)
            guard loc == 0 || text.character(at: loc - 1) == 10 else { return }   // wrapped continuation: no number
            let baseline = top + rect.minY + self.baseFont.ascender
            draw(self.lines.line(at: loc), baseline: baseline)
        }
        let extra = lm.extraLineFragmentRect
        if !extra.isEmpty && extra.maxY + top > 0 && extra.minY + top < bounds.height {
            draw(lines.count, baseline: top + extra.minY + baseFont.ascender)
        }
    }
}
#endif
