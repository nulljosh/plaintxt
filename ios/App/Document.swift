// A file is a String. FileDocument gives open, save, autosave, rename, iCloud,
// versions and the recent-files menu for free. That is the whole point.

import SwiftUI
import UniformTypeIdentifiers

/// How a file's lines end on disk. In memory every line ends in \n, so the line math has one case.
enum LineEnding: String, CaseIterable, Identifiable {
    case lf = "\n", crlf = "\r\n", cr = "\r"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .lf: "LF"
        case .crlf: "CRLF"
        case .cr: "CR"
        }
    }

    // ponytail: the first ending decides, so a mixed file comes out uniform once it is edited. Count them if that bites.
    static func detect(_ data: Data) -> LineEnding {
        guard let i = data.firstIndex(where: { $0 == 10 || $0 == 13 }) else { return .lf }
        if data[i] == 10 { return .lf }
        return data.index(after: i) < data.endIndex && data[data.index(after: i)] == 10 ? .crlf : .cr
    }
}

enum TextEncoding: String, CaseIterable, Identifiable {
    case utf8 = "UTF-8", utf16 = "UTF-16", windows1252 = "Windows-1252", latin1 = "ISO Latin 1"
    var id: String { rawValue }
    var encoding: String.Encoding {
        switch self {
        case .utf8: .utf8
        case .utf16: .utf16
        case .windows1252: .windowsCP1252
        case .latin1: .isoLatin1
        }
    }

    /// Decodes the bytes, trying UTF-16 (only with a byte order mark), UTF-8, Windows-1252, then Latin-1, which never fails.
    static func decode(_ data: Data) -> (String, TextEncoding) {
        let marked = data.count % 2 == 0 && (data.starts(with: [0xff, 0xfe]) || data.starts(with: [0xfe, 0xff]))
        for e in (marked ? [utf16, utf8, windows1252, latin1] : [utf8, windows1252, latin1]) {
            if let s = String(data: data, encoding: e.encoding) { return (s, e) }
        }
        return (String(decoding: data, as: UTF8.self), .utf8)
    }
}

struct TextDocument: FileDocument {
    // Markdown and code conform to plain text, so they open; listing them as writable
    // is what keeps a .md or .swift file editable in place instead of read-only.
    static var readableContentTypes: [UTType] { [.plainText, .sourceCode, .text] }
    static var writableContentTypes: [UTType] { readableContentTypes }

    var text = ""
    var type: UTType = .plainText
    var encoding = TextEncoding.utf8
    var lineEnding = LineEnding.lf

    init() {}

    init(data: Data, type: UTType) {
        // A file saves back in the encoding and line endings it opened with, unless the reader changes them.
        let (decoded, encoding) = TextEncoding.decode(data)
        lineEnding = LineEnding.detect(data)
        text = decoded.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        self.encoding = encoding
        self.type = type
    }

    var data: Data {
        if type.conforms(to: .json) { Config.apply(text) }   // saving the settings file applies it
        let formatted = Formatter.format(text, type: type)
        let out = lineEnding == .lf ? formatted : formatted.replacingOccurrences(of: "\n", with: lineEnding.rawValue)
        // A character the chosen encoding cannot hold saves the file as UTF-8 instead of losing it.
        return out.data(using: encoding.encoding) ?? Data(out.utf8)
    }

    init(configuration: ReadConfiguration) throws {
        // A directory or a symlink has no regular contents; say so instead of showing an empty editor.
        guard let d = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.init(data: d, type: configuration.contentType)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
