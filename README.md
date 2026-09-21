<img src="icon.svg" width="80" style="border-radius:18px">

# plain

![version](https://img.shields.io/badge/version-v1.0.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fplaintxt-black?logo=github)](https://github.com/nulljosh/plaintxt)

They don't make them like Sublime Text anymore. Editors are a div soup, a browser in a trench coat, or a subscription.

A text file is a string. Opening, saving, undo, selection, scrolling, accessibility: the OS already does all of that better than any JavaScript will. Nobody should have to rebuild it.

That's the gap.

Live at [plain.heyitsmejosh.com](https://plain.heyitsmejosh.com).

<p><img src="screenshots/mac.png" width="560" alt="Plain on Mac colouring a Swift file"> <img src="screenshots/iphone.png" width="180" alt="Plain on iPhone"></p>

<img src="progress.svg" width="460">

## What it does

Plain opens a text file, a Markdown file, or a source file and lets you type. No preview pane: the file is a string and stays one. Mac and iPhone and iPad, one codebase. Autosave, versions, iCloud, Open Recent, tabs, undo and redo all come from the system. The app adds a monospaced toggle, a font size, and a line/word/character count in the corner.

Open a `.md` and headings, emphasis, links and code spans get colour. Open a `.swift`, `.py`, `.js` or anything else that counts as source and keywords, strings, numbers and comments do. Same string, same text view; the colour is attributes on it, not a rendering layer. Plain `.txt` stays plain.

On the Mac, press ⌘↩ in a code file and Plain asks a model running on your machine (Ollama, `qwen2.5-coder` by default) to fill in at the cursor. Nothing leaves the computer. No Ollama, no button does anything.

Settings are a text file. Launch Plain on the Mac with nothing to open and it opens `plain.json`: font size, monospaced, the completion model, and the five colours as hex. Edit, save, done. Like Sublime.

The command line side opens a file in the app or counts it.

```
plain notes.txt          open in Plain (.txt, .md, any code)
plain stat notes.txt     3 lines, 12 words, 71 chars
cat x | plain stat       counts from stdin
```

## Why this and not Monaco

David Bushell tried canvas, then contenteditable, then a textarea, and landed on the same lesson: the native thing wins. This is that lesson taken all the way. No web view, no rendering layer, no cursor drawn by hand.

## Run it

```
cd ios && xcodegen generate && open Plain.xcodeproj                  # needs macOS 26 / iOS 26
ollama pull qwen2.5-coder:1.5b-base                                    # optional, for ⌘↩
swiftc -O -o plain ios/App/Stats.swift cli/main.swift      # the CLI
cd ios && xcodebuild test -scheme Plain -destination "platform=macOS" -quiet   # tests
```

## Architecture

<img src="architecture.svg" width="600">
