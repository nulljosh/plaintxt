import SwiftUI

struct EditorView: View {
    @Binding var document: TextDocument
    @AppStorage("monospaced") private var monospaced = false
    @AppStorage("fontSize") private var fontSize = 15.0
    @AppStorage("formatOnSave") private var formatOnSave = false
    @State private var text = AttributedString()
    @State private var selection = AttributedTextSelection()
    @State private var completing = false
    @State private var notice: String?
    @State private var finding = false

    private var highlighter: Highlighter { Highlighter(type: document.type, size: fontSize, monospaced: monospaced) }

    // Colour once, before the editor ever sees the string: no programmatic edit on open, so no
    // "Edited" flag and no cursor reset when a Mac tab comes back.
    init(document: Binding<TextDocument>) {
        _document = document
        let d = UserDefaults.standard
        var a = AttributedString(document.wrappedValue.text)
        Highlighter(type: document.wrappedValue.type, size: d.object(forKey: "fontSize") as? Double ?? 15, monospaced: d.bool(forKey: "monospaced")).apply(&a)
        _text = State(initialValue: a)
    }

    var body: some View {
        #if os(macOS)
        HSplitView {
            FileListView(document: $document)
            macosContent
        }
        #else
        editorPane
        #endif
    }

    private var macosContent: some View {
        VStack(spacing: 0) {
            editorPane
            Divider()
            #if os(macOS)
            TabView {
                ChatView(document: $document)
                    .tabItem { Label("Agent", systemImage: "bubble.left") }
                OutputPane(document: $document)
                    .tabItem { Label("Output", systemImage: "square.and.pencil") }
                TerminalPane()
                    .tabItem { Label("Terminal", systemImage: "terminal") }
            }
            .frame(minHeight: 100, maxHeight: 250)
            #else
            EmptyView()
            #endif
        }
    }

    private var editorPane: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text, selection: $selection)
                // Colour lives in the view; the document stays a String.
                .onChange(of: text) { if String(text.characters) != document.text { document.text = String(text.characters); recolor() } }
                .onChange(of: document.text) { if String(text.characters) != document.text { text = AttributedString(document.text); recolor() } }  // undo, revert, iCloud
                .onChange(of: fontSize) { recolor() }
                .onChange(of: monospaced) { recolor() }
                .lineSpacing(fontSize * 0.25)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .scrollDismissesKeyboard(.interactively)
                #endif
                .findNavigator(isPresented: $finding)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            footer
        }
        .toolbar { toolbar }
    }

    // Ask the local model to fill in at the cursor. Inserts at wherever the cursor is when the answer arrives.
    private func complete() {
        guard !completing, case .insertionPoint(let i) = selection.indices(in: text) else { return }
        let s = String(text.characters)
        let k = s.index(s.startIndex, offsetBy: text.characters.distance(from: text.startIndex, to: i))
        completing = true
        Task {
            defer { completing = false }
            do {
                let out = try await Complete.fill(prefix: String(s[..<k]), suffix: String(s[k...]))
                guard case .insertionPoint(let j) = selection.indices(in: text) else { return }
                text.transform(updating: &selection) { $0.insert(AttributedString(out), at: j) }
            } catch {
                notice = error.localizedDescription
                try? await Task.sleep(for: .seconds(4))
                notice = nil
            }
        }
    }

    private func run(_ tool: TextTool) {
        let new = tool.apply(document.text)
        guard new != document.text else { notice = "\(tool.title): nothing to change"; clearNotice(); return }
        document.text = new
        text = AttributedString(new)
        recolor()
    }

    private func clearNotice() {
        Task { try? await Task.sleep(for: .seconds(3)); notice = nil }
    }

    private func recolor() {
        let h = highlighter
        text.transform(updating: &selection) { h.apply(&$0) }
    }

    private var footer: some View {
        HStack {
            if let notice { Text(notice).foregroundStyle(.red).lineLimit(1) }
            Spacer()
            Text(Stats(document.text).summary).monospacedDigit().foregroundStyle(.secondary)
        }
            .font(.footnote)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            #if os(macOS)
            if document.type.kind == .code {
                Button(action: complete) { Label("Complete", systemImage: completing ? "ellipsis" : "text.append") }
                    .help("Complete at cursor with the local model (⌘↩)")
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(completing)
            }
            #endif
            Button { finding.toggle() } label: { Label("Find and Replace", systemImage: "magnifyingglass") }
                .help("Find and replace")
            Menu {
                ForEach(TextTool.allCases) { tool in
                    Button { run(tool) } label: { Label(tool.title, systemImage: tool.icon) }
                }
            } label: { Label("Text Tools", systemImage: "wand.and.stars") }
                .help("Sort, de-duplicate, change case, fix whitespace")
            Toggle(isOn: $monospaced) { Label("Monospaced", systemImage: "textformat") }
                .help("Monospaced font")
                .keyboardShortcut("m", modifiers: [.command, .shift])
            #if os(macOS)
            Toggle(isOn: $formatOnSave) { Label("Format on Save", systemImage: "sparkles") }
                .help("Format on save with prettier/black/swiftformat")
                .keyboardShortcut("s", modifiers: [.command, .shift])
            #endif
            Button { fontSize = max(9, fontSize - 1) } label: { Label("Smaller", systemImage: "textformat.size.smaller") }
                .help("Smaller text")
                .keyboardShortcut("-", modifiers: .command)
            Button { fontSize = min(40, fontSize + 1) } label: { Label("Bigger", systemImage: "textformat.size.larger") }
                .help("Bigger text")
                .keyboardShortcut("=", modifiers: .command)
            Button { fontSize = 15 } label: { Label("Actual Size", systemImage: "textformat.size") }
                .help("Reset text size")
                .keyboardShortcut("0", modifiers: .command)
        }
    }
}
