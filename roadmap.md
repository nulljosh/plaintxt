# Plain roadmap

## Next

## Done
- 2026-10-05: iOS gets line numbers with a gutter that follows the text, Go to Line, an outline of headings and symbols that jumps the caret, and a read-only Markdown preview (side by side on iPad). The iOS editor is now a wrapped UITextView; TextDocument is unchanged. Unit tests for the line math, outline and preview parsing.
- 2026-09-03: v1.0.0 scaffold. DocumentGroup + TextEditor, iOS+macOS one target, CLI, Stats self-check.
- 2026-09-03: Markdown and code files save in place; UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace. Syntax highlighting for code/Markdown blocks via regex Highlighter. Local Ollama completion on macOS (⌘↩, qwen2.5-coder). Deployment target bumped to iOS 26/macOS 26. Completions stop at blank line.
- 2026-09-03: Landing page demo. Replaced static screenshot with a live textarea where visitors type, running the same line/word/grapheme counting logic as the native app in JavaScript. Uses Intl.Segmenter for proper grapheme handling. Styled inside device-mac chrome with real title bar and traffic lights. Deployed to plain.heyitsmejosh.com.

## Known
- Title shows "Edited" right after opening any file, plain .txt included, with no attribute mutation on our side (verified 2026-09-03). Comes from the iOS 26 AttributedString TextEditor inside DocumentGroup. Cosmetic. Retest on the next OS point release before working around it.

## Considered
- Rewrite the Mac app in C/C++/Rust. No. It is already native (SwiftUI over AppKit's text view); the language is not where time goes. Revisit only if a measured hot path appears.
- Web: type, edit and use Plain in the browser (a textarea plus the same regex colouring; keep the no-editor-code rule). Deferred; landing demo is sufficient for launch.
- [ ] native (kmp) port, sibling apps have one, this doesn't (project-sync 2026-09-05)

## Ingested 2026-10-16

## Ingested 2026-10-30

## Ingested 2026-10-31
- [ ] Text Editor. Clarify: Joshua's note is only this title and description, is it the App Store subtitle/category, or a feature ask?

## Ingested 2026-11-03
- [ ] App Review sent an "issue with your submission" email (Nov 1-2): read the reason in Resolution Center (asc web review show), no reply without Joshua's yes

## Ingested 2026-11-06
- [ ] Full rename to Plain.Txt or something simple. About 42 files. Bundle id com.nulljosh.plain stays. Run asc-name-creator first, the store name must be unique.
- [ ] Feature candidates: encoding and line-ending picker, quick open by filename (Cmd-P), tab width in plain.json, Shortcuts actions, a windowed large-file mode.
- [ ] Stack is Swift: SwiftUI shell, UITextView through UIViewRepresentable. Keep it. Profile a very large file before changing anything.

## Stashed 2026-11-07
- [ ] Next App Store version: the Mac 1.0.0 support and marketing URLs still point at plain.heyitsmejosh.com (heyitsmejosh.com lapsed, the link is dead; App Review can reject on it). Set both to https://plaintxt.jaybulb.com in the new version's localizations. Live versions cannot be edited.
