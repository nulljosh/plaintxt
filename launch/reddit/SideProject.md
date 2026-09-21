# r/SideProject

Gate: none, low karma tolerance. Post any time.

## Title
Built a text editor that's mostly the OS, not my code

## Body
I kept opening text editors that felt like a browser wearing a trench coat, or a subscription for something that used to just work. So I built Plaintxt: open a file, type, save. That's the whole app.

The idea was to write as little editor code as possible. It's a SwiftUI DocumentGroup around a plain TextEditor. Open, save, autosave, undo, find, dictation, VoiceOver, iCloud versions, all of that comes from the OS for free, because DocumentGroup and TextEditor already do it better than I could rewrite it. I added three things on top: a monospaced toggle, a font size stepper, and a status line with line/word/character counts. There's also a tiny command line tool that shares the counting logic with the app.

It's live on Mac, iPhone and iPad. $0.99 upfront on iOS, free on the web at plain.heyitsmejosh.com. Would like feedback on what's actually missing before I add anything, since the whole point was to not add things speculatively.
