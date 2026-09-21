Skip: no technical hook

# Hacker News: Plaintxt

## Title (68 chars)
Show HN: Plaintxt – a text editor that writes no editor code

## Body
Plaintxt is a SwiftUI DocumentGroup wrapped around a plain TextEditor, shipped from one target for macOS, iOS and iPadOS, plus a small command line tool that shares its only real piece of logic (line, word and grapheme counts, counted by grapheme cluster so multi-codepoint emoji count as one character). The whole file model is a String read in and written back out as UTF-8, because a plain text file has no structure worth modeling beyond its bytes.

Everything a text editor gets judged on, open, save, autosave, undo, find, dictation, VoiceOver, iCloud Drive, document versions, comes straight from DocumentGroup and TextEditor instead of being rebuilt. The app adds three things the framework doesn't give you: a monospaced toggle, a font size stepper, and a status line.

It's $0.99 upfront on iOS, free on the web at plain.heyitsmejosh.com. Source is on GitHub. Curious what people think of building an editor by mostly not building one.
