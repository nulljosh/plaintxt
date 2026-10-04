import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import Plain

final class StatsTests: XCTestCase {
    func testEmpty() { XCTAssertEqual(Stats(""), Stats(lines: 1, words: 0, characters: 0)) }
    func testOneLine() { XCTAssertEqual(Stats("hello world"), Stats(lines: 1, words: 2, characters: 11)) }
    func testTrailingNewline() { XCTAssertEqual(Stats("a\nb\n").lines, 2) }
    func testBlankLine() { XCTAssertEqual(Stats("a\n\nb").lines, 3) }
    func testGrapheme() { XCTAssertEqual(Stats("🍋‍🟩").characters, 1) }
    func testWhitespace() { XCTAssertEqual(Stats("  two\twords  ").words, 2) }
}

final class HighlightTests: XCTestCase {
    func runs(_ s: String, _ t: UTType) -> [(String, Color?)] {
        var a = AttributedString(s)
        Highlighter(type: t, size: 15, monospaced: false).apply(&a)
        return a.runs.map { (String(a.characters[$0.range]), $0.foregroundColor) }
    }
    func testKeywordAndComment() {
        let r = runs("let x = 1 // hi", .swiftSource)
        XCTAssertEqual(r.first?.0, "let"); XCTAssertEqual(r.first?.1, Config.color("keywordColor"))
        XCTAssertEqual(r.last?.0, "// hi"); XCTAssertEqual(r.last?.1, Config.color("commentColor"))
    }
    func testHashComments() { XCTAssertEqual(runs("x = 1 # hi", .pythonScript).last?.0, "# hi") }
    func testMarkdownHeading() { XCTAssertEqual(runs("# Title\n`x`", .markdown).first?.0, "# Title") }
    func testPlainUntouched() { let r = runs("let x", .plainText); XCTAssertEqual(r.count, 1); XCTAssertNil(r.first?.1) }
    func testKindDetection() {
        XCTAssertEqual(UTType.markdown.kind, .markdown); XCTAssertEqual(UTType.json.kind, .code)
        XCTAssertEqual(UTType.shellScript.kind, .code); XCTAssertEqual(UTType.plainText.kind, .text)
    }
    func testUnterminatedStringDoesNotHang() { _ = runs(String(repeating: "\"", count: 5000), .swiftSource) }
}

final class DocumentTests: XCTestCase {
    func read(_ d: Data, _ t: UTType = .plainText) -> TextDocument { TextDocument(data: d, type: t) }
    func testUTF8() { XCTAssertEqual(read(Data("héllo".utf8)).text, "héllo") }
    func testInvalidBytesStillOpen() { XCTAssertTrue(read(Data([0xff, 0xfe, 0x41])).text.hasSuffix("A")) }
    func testLatin1Fallback() { XCTAssertEqual(read(Data([0x63, 0x61, 0x66, 0xe9])).text, "café") }
    func testEmpty() { XCTAssertEqual(read(Data()).text, "") }
    func testRoundTrip() throws {
        var d = TextDocument(); d.text = "a\nb"
        XCTAssertEqual(d.data, Data("a\nb".utf8))
    }
    func testTypeKept() { XCTAssertEqual(read(Data(), .swiftSource).type, .swiftSource) }
    func testSavingJSONAppliesConfig() {
        var d = TextDocument(data: Data(), type: .json); d.text = #"{"fontSize": 33}"#
        _ = d.data; XCTAssertEqual(UserDefaults.standard.double(forKey: "fontSize"), 33)
        UserDefaults.standard.removeObject(forKey: "fontSize")
    }
}

final class ConfigTests: XCTestCase {
    override func tearDown() { for k in Config.defaults.keys { UserDefaults.standard.removeObject(forKey: k) } }
    func testAppliesKnownKeys() {
        XCTAssertTrue(Config.apply(#"{"fontSize": 21, "junk": 1}"#))
        XCTAssertEqual(UserDefaults.standard.double(forKey: "fontSize"), 21)
        XCTAssertNil(UserDefaults.standard.object(forKey: "junk"))
    }
    func testRejectsProseAndUnrelatedJSON() {
        XCTAssertFalse(Config.apply("hello")); XCTAssertFalse(Config.apply(#"{"name": "x"}"#)); XCTAssertFalse(Config.apply("[1,2]"))
    }
    func testWrongTypeIgnored() {
        XCTAssertTrue(Config.apply(#"{"fontSize": "big", "monospaced": true}"#))
        XCTAssertNil(UserDefaults.standard.object(forKey: "fontSize"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "monospaced"))
    }
    func testColour() {
        let def = Config.color("keywordColor")
        XCTAssertTrue(Config.apply(##"{"keywordColor": "#000000"}"##))
        XCTAssertEqual(Config.color("keywordColor"), Color(red: 0, green: 0, blue: 0))
        XCTAssertTrue(Config.apply(#"{"keywordColor": "red"}"#))
        XCTAssertEqual(Config.color("keywordColor"), def)
    }
    func testFileCreatedWithDefaults() throws {
        let d = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: Config.url)) as? [String: Any])
        XCTAssertEqual(Set(d.keys), Set(Config.defaults.keys))
    }
}

final class CompleteTests: XCTestCase {
    func testOfflineIsReported() async {
        guard (try? Data(contentsOf: URL(string: "http://localhost:11434/api/version")!)) == nil else {
            let out = try? await Complete.fill(prefix: "func add(a: Int, b: Int) -> Int {\n    ", suffix: "\n}")
            XCTAssertTrue(out?.contains("a + b") == true, "live Ollama fills the middle"); return
        }
        do { _ = try await Complete.fill(prefix: "x", suffix: ""); XCTFail("should throw") }
        catch { XCTAssertEqual(error.localizedDescription, CompleteError.offline.localizedDescription) }
    }
    func testMessages() {
        XCTAssertTrue(CompleteError.badStatus(404).localizedDescription.contains("ollama pull"))
        XCTAssertTrue(CompleteError.badStatus(500).localizedDescription.contains("500"))
    }
}

final class TextToolTests: XCTestCase {
    func testSortsLinesNaturally() { XCTAssertEqual(TextTool.sortLines.apply("b\na10\na2\n"), "a2\na10\nb\n") }
    func testRemovesDuplicatesKeepingOrder() { XCTAssertEqual(TextTool.uniqueLines.apply("x\ny\nx\nz\ny"), "x\ny\nz") }
    func testReversesLines() { XCTAssertEqual(TextTool.reverseLines.apply("1\n2\n3"), "3\n2\n1") }
    func testTrimsTrailingWhitespaceOnly() { XCTAssertEqual(TextTool.trimTrailing.apply("a  \n  b\t\n"), "a\n  b\n") }
    func testChangesCase() {
        XCTAssertEqual(TextTool.uppercase.apply("hi"), "HI")
        XCTAssertEqual(TextTool.lowercase.apply("HI"), "hi")
        XCTAssertEqual(TextTool.titleCase.apply("hello big world"), "Hello Big World")
    }
    func testTabsAndSpacesRoundTrip() {
        XCTAssertEqual(TextTool.tabsToSpaces.apply("\tx"), "    x")
        XCTAssertEqual(TextTool.spacesToTabs.apply("    x"), "\tx")
    }
    func testEmptyTextIsSafe() { for t in TextTool.allCases { _ = t.apply("") } }
}
