# Architecture

Plain is a native text editor for iOS and macOS. It uses the system's DocumentGroup to manage files (open, save, versions, iCloud sync, recent files all built in). The file is a plain string, passed through the system's native TextEditor view. Syntax highlighting (regex-based), word/line/character count, and optional format-on-save (macOS only, via prettier/black/swiftformat) are the only extras. No web view, no rendering layer, no custom cursor.

## How it runs

**Mac:** User opens a text file (`.txt`, `.md`, source file). Plain boots with a DocumentGroup interface (open/new/recent). The file opens in a native TextEditor. Type to edit. Cmd+S saves (or auto-save). Cmd+Z/Cmd+Y undo/redo. Cmd-backtick toggles monospaced font. Command+Enter (if a local Ollama instance is running) asks the model to complete at the cursor. Versions and iCloud sync are managed by the system. Close the window, reopen the file, it's exactly where you left it. Edit `~/Library/Application Support/Plain/plain.json` to change font size, colors, and formatting preferences.

**iPhone/iPad:** Same editor, same file format, same sync via iCloud. Monospace toggle and font size adjustment in-app. No Ollama completion on iOS (Process API unavailable). Settings edited via in-app UI instead of a JSON file.

**CLI:** `plain <file>` opens the file in Plain. `plain stat <file>` prints line/word/character count to stdout.

## Core app

| File | What it owns |
|---|---|
| `ios/App/PlainApp.swift` | App entry point. Uses `DocumentGroup` to manage the file lifecycle (open, new, save, versions, iCloud). Passes the file to `EditorView`. |
| `ios/App/Document.swift` | `FileDocument` implementation. Reads UTF-8 text in, writes UTF-8 text out. Calls `Formatter.format()` on save (macOS only) if formatting is enabled. Detects file type and language via `UTType`. |
| `ios/App/EditorView.swift` | Main UI. Native SwiftUI `TextEditor` wrapped in a VStack with a toolbar (monospace toggle, font size buttons, stats footer). Command+Enter (macOS) triggers completion. Reads the current file from the document and displays it. All edits update the document automatically. |
| `ios/App/Stats.swift` | Counts lines, words, and grapheme clusters (user-perceived characters, handles emoji and combining marks correctly). Shared with the CLI. |
| `ios/App/Config.swift` | Settings loader. Reads `~/Library/Application Support/Plain/plain.json` on macOS. Returns defaults if missing. Includes font size, monospaced toggle, formatter choice, and color palette as hex strings. User can edit the JSON directly (Sublime Text style). iOS reads/writes settings via `UserDefaults` instead. |
| `ios/App/Formatter.swift` | On-save formatting. Shells out to `prettier` (JS/JSON/Markdown), `black` (Python), or `swiftformat` (Swift) based on file type. Gracefully falls back (does not format) if the tool is missing or fails. Only on macOS; iOS skips this. |
| `ios/App/FileListView.swift` | File browser down the side of the window, macOS only. Lists the files git knows about in the current project. Click one to open it in a new tab. Reads the list once when it appears. |
| `ios/App/ChatView.swift` | Chat panel down the side, macOS only. You type a question, it goes to the model running on your own Mac, the answer comes back below. One question at a time, and the conversation is not kept after you close it. |
| `ios/App/Complete.swift` | Autocomplete. Press the key and Plain asks the model running on this Mac to carry on writing from the cursor. One request, text lands in the document. Mac only, because the model listens on this machine. Says so plainly if it is not running. |
| `ios/App/TerminalPane.swift` | A terminal at the bottom of the window, macOS only. Type a command, see what it prints. No fancy terminal features. |
| `ios/App/OutputPane.swift` | Build and test output, macOS only. Scrolls the output and spots file-and-line references in error messages, so clicking one jumps you to that line. |
| `ios/App/Highlight.swift` | Syntax highlighting via regex. Detects language from file extension or UTType. Applies NSAttributedString attributes (color, weight) to keywords, strings, numbers, comments, and Markdown syntax. Highlights code spans, headings, and emphasis in Markdown. Pure UTF-8 string underneath, no separate rendering layer. |

## Checks and tests

| File | What it owns |
|---|---|
| `ios/Checks/main.swift` | Sanity tests. Verifies that `Formatter` and `Config` work correctly, that syntax highlighting doesn't crash on edge cases, and that `Stats` counts correctly. Run `swiftc ios/App/Config.swift ios/App/Formatter.swift ios/App/Highlight.swift ios/App/Stats.swift ios/App/Document.swift ios/Checks/main.swift -o /tmp/checks && /tmp/checks`. |
| `ios/Tests/PlainTests.swift` | Unit tests for the app. Verifies file I/O, syntax highlighting, word/line counts, and formatter invocation. Run via Xcode. |

## CLI

| File | What it owns |
|---|---|
| `cli/main.swift` | Command-line interface. `plain <file>` uses `NSWorkspace.shared.open()` to open the file in Plain. `plain stat <file>` calls `Stats.count()` and prints the result. Reads from stdin if no file is given (`plain stat` with a pipe). Reuses `Stats.swift` with no duplication. |

## Landing page

| File | What it owns |
|---|---|
| `landing/index.html` | Marketing landing page. Hero, features, screenshots, download link. |
| `landing/privacy.html` | Privacy policy. |
| `landing/devices.css` | Styling for the phone and laptop frames the screenshots sit inside on the landing page. |
| `deploy.sh` | Deployment script. Builds the app and deploys the landing page to the web. |

## Design and philosophy

- **No custom rendering:** The editor is a native TextEditor, not a canvas, not a web view. All editing, undo/redo, selection, scrolling, and accessibility come from the OS.
- **No editor layer:** If a feature needs direct NSTextView/UITextView access (e.g., custom cursor), it goes through NSViewRepresentable/UIViewRepresentable, keeping the Document clean. The file stays a plain string.
- **Monospace only in the editor:** The toolbar and UI use the system sans font (SF Pro). Monospace is opt-in via a toggle and applies only inside the text editing area.
- **Settings as text:** On macOS, `plain.json` is a readable text file, not a plist or a database. Users can edit it directly and see their changes reflected on restart.
- **Format-on-save is optional:** Formatting is a user choice (toggle in settings or the JSON). If a formatter is missing or fails, save still succeeds (no error thrown). The feature degrades gracefully.
- **Syntax highlighting is attributes, not markup:** Highlighting is NSAttributedString attributes applied to the same plain string. No separate rendering layer, no re-parsing on every keystroke.

## Gotchas

- **TextEditor on iOS:** SwiftUI's TextEditor is fully native and supports undo/redo, but with some limitations compared to UITextView directly. Performance is good for typical documents (under 100KB).
- **Ollama availability:** The Cmd+Enter completion only works if `ollama serve` is running and the model is available locally. The button does nothing if Ollama is not running. There is no error message; silence means unavailable. This is by design (no API call to a server).
- **Process API on iOS:** iOS does not have a Process API, so formatting and completion are macOS-only. The iOS app saves without formatting.
- **iCloud sync delays:** iCloud syncing can take seconds. If a user saves on one device and opens on another immediately, they may not see the latest version. Normal for iCloud Documents.
- **Settings file format:** The `plain.json` schema is not validated. Invalid JSON silently falls back to defaults. Users are responsible for keeping it valid JSON.
- **Language detection:** Syntax highlighting detection is based on file extension first, then UTType. Some files may be misidentified (e.g., a `.sh` script that is actually YAML). Users can't override the language in-app yet.
