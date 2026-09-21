# Product Hunt: Plaintxt

## Name
Plaintxt

## Tagline (56 chars)
A text editor that writes no editor code

## Description (247 chars)
Open a file, type, save. That's the whole app. Plaintxt reads and writes text, Markdown and code files in place on Mac, iPhone and iPad, with line, word and character counts and light syntax colouring. No account, no sync, no tracking.

## Topics
- Productivity
- Mac
- Developer Tools

## First comment (maker story)
Text editors used to be a solved problem. Now they're a div soup, a browser in a trench coat, or a subscription. I wanted something closer to Sublime Text: open a file, type, save, and get out of the way.

So I built Plaintxt around one idea: a text file is just a string, and the OS already knows how to handle strings better than any app I could write. SwiftUI's DocumentGroup gives me open, save, autosave, rename, Open Recent and iCloud versioning for free. TextEditor gives me undo, redo, selection, find, dictation and VoiceOver, because under the hood it's the same NSTextView and UITextView every native app uses. I added exactly three things on top: a monospaced toggle, a font size stepper, and a status line with counts. That's it.

There's also a small command line tool that shares the same counting logic as the app, so `plain stat` works from a terminal without duplicating anything.

No line numbers yet, no syntax highlighting beyond light regex colouring for code and Markdown, no multiple encodings. Those need dropping straight to NSTextView, which is the exact shortcut the whole project is built to avoid. They'll come when a real file needs them.

Plaintxt is $0.99 upfront on iOS, free on the web.

## Pricing line
$0.99 upfront on iOS, free on the web.

## Links
- Web: https://plain.heyitsmejosh.com
- App Store: https://apps.apple.com/app/id6809841903
- GitHub: https://github.com/nulljosh/plaintxt
