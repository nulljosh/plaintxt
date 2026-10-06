# Plain roadmap

## Next
- [ ] Live Agent IDE demo on the landing page: clickable file sidebar + syntax-highlighted code + Chat/Build/Terminal tabs, using real content pulled from the repo (Stats.swift, README, Checks/main.swift), not placeholder text. Keep it framed as Mac-only (the real feature is macOS-only) rather than switching device frame by visitor platform. The top "What it looks like" editor demo can stay/become cross-platform (device frame by user agent) since that part of the app really is cross-platform.
- [ ] Refresh root `screenshots/mac.png` and `screenshots/iphone.png` referenced by README.md, predate the IDE feature bump (file browser, agent chat, output/terminal panes)
- [ ] Line numbers, Go to Line, outline and preview on the Mac (iOS has them)
- [ ] Current line highlight
- [ ] Extend IDE panes to iOS (currently macOS only)

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
