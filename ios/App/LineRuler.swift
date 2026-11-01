#if os(macOS)
import AppKit
import SwiftUI

/// Line numbers beside the Mac editor. SwiftUI's TextEditor keeps its selection, Go to Line and Outline; this
/// only puts a ruler on the NSTextView underneath it and reads the line positions through TextKit 2.
final class LineRuler: NSRulerView {
    private var lines = LineIndex("")

    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        textView.enclosingScrollView?.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSText.didChangeNotification, object: textView)
        NotificationCenter.default.addObserver(self, selector: #selector(redraw), name: NSView.boundsDidChangeNotification,
                                               object: textView.enclosingScrollView?.contentView)
        refresh()
    }
    required init(coder: NSCoder) { fatalError() }

    @objc func refresh() {
        guard let tv = clientView as? NSTextView else { return }
        lines = LineIndex(tv.string)
        ruleThickness = CGFloat(max(2, String(lines.count).count)) * 8 + 18
        needsDisplay = true
    }
    @objc func redraw() { needsDisplay = true }

    // The stock ruler paints a light grey strip; this one stays on the editor's own background with a hairline edge.
    override var isOpaque: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill(using: .copy)
        NSColor.separatorColor.setFill()
        NSRect(x: bounds.maxX - 1, y: dirtyRect.minY, width: 1, height: dirtyRect.height).fill()
        drawHashMarksAndLabels(in: dirtyRect)
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let tv = clientView as? NSTextView, let tlm = tv.textLayoutManager, let tcm = tlm.textContentManager else { return }
        let size = max(9, (tv.font?.pointSize ?? 13) * 0.8)
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: .medium),
                                                    .foregroundColor: NSColor.labelColor.withAlphaComponent(0.65)]
        let top = convert(NSPoint(x: 0, y: tv.textContainerOrigin.y), from: tv).y
        let start = tlm.textViewportLayoutController.viewportRange?.location ?? tcm.documentRange.location
        // One layout fragment is one paragraph, so one number; a wrapped line keeps a single number at its top.
        tlm.enumerateTextLayoutFragments(from: start, options: [.ensuresLayout]) { frag in
            let y = top + frag.layoutFragmentFrame.minY
            if y > self.bounds.maxY { return false }
            let label = "\(self.lines.line(at: tcm.offset(from: tcm.documentRange.location, to: frag.rangeInElement.location)))" as NSString
            let box = label.size(withAttributes: attrs)
            let lineHeight = frag.textLineFragments.first?.typographicBounds.height ?? box.height
            label.draw(at: NSPoint(x: self.ruleThickness - box.width - 8, y: y + (lineHeight - box.height) / 2), withAttributes: attrs)
            return true
        }
    }
}

/// Finds the editor's NSTextView once the TextEditor is on screen and shows or hides the ruler on it.
struct LineRulerAttach: NSViewRepresentable {
    var shown: Bool
    func makeNSView(context: Context) -> AttachView { AttachView() }
    func updateNSView(_ view: AttachView, context: Context) { view.shown = shown }

    final class AttachView: NSView {
        var shown = false { didSet { if shown != oldValue { attach() } } }
        override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); attach() }

        /// The TextEditor builds its text view a beat after this view joins the window, so try a few times.
        func attach(tries: Int = 10) {
            guard let root = window?.contentView else { return }
            guard let tv = Self.textView(in: root), let scroll = tv.enclosingScrollView else {
                if tries > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.attach(tries: tries - 1) } }
                return
            }
            if !(scroll.verticalRulerView is LineRuler) { scroll.verticalRulerView = LineRuler(textView: tv) }
            scroll.hasVerticalRuler = true
            scroll.rulersVisible = shown
        }

        static func textView(in view: NSView) -> NSTextView? {
            if let tv = view as? NSTextView, tv.isEditable { return tv }
            for v in view.subviews { if let tv = textView(in: v) { return tv } }
            return nil
        }
    }
}
#endif
