# r/iOSProgramming

Gate: "Show and Tell" flair required. Consider posting in the weekly self-promo thread as the safer option.

## Title
[Show and Tell] A text editor built around DocumentGroup, almost no custom code

## Body
Shipped Plaintxt, a text editor for Mac, iPhone and iPad built from one xcodegen target. The core bet was that DocumentGroup and TextEditor already handle everything an editor gets judged on: open, save, autosave, rename, Open Recent, undo, find, dictation, VoiceOver, iCloud Drive and document versions. TextDocument conforms to FileDocument and just reads/writes UTF-8 bytes into a String, no custom file model.

The only real logic is a Stats.swift that counts lines, words and grapheme clusters (grapheme, not UTF-16 units, so multi-codepoint emoji count as one character), shared between the app and a small CLI target. Syntax colouring is a handful of regexes over AttributedString, recoloured per keystroke, nothing fancier yet.

$0.99 upfront on iOS, free on the web at plain.heyitsmejosh.com. Happy to talk through the DocumentGroup approach or where it breaks down (no line numbers yet, that needs dropping to NSTextView directly).
