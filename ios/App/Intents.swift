// Shortcuts actions: the Text Tools and the counts, on any text, without opening the app.

import AppIntents

extension TextTool: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Text Tool"
    static let caseDisplayRepresentations: [TextTool: DisplayRepresentation] = [
        .sortLines: "Sort Lines",
        .uniqueLines: "Remove Duplicate Lines",
        .reverseLines: "Reverse Lines",
        .trimTrailing: "Trim Trailing Spaces",
        .uppercase: "UPPERCASE",
        .lowercase: "lowercase",
        .titleCase: "Title Case",
        .tabsToSpaces: "Tabs to Spaces",
        .spacesToTabs: "Spaces to Tabs",
    ]
}

struct CleanUpTextIntent: AppIntent {
    static let title: LocalizedStringResource = "Clean Up Text"
    static let description = IntentDescription("Runs one of Plaintxt's Text Tools on some text and returns the result.")

    @Parameter(title: "Tool") var tool: TextTool
    @Parameter(title: "Text", inputOptions: String.IntentInputOptions(multiline: true)) var text: String

    static var parameterSummary: some ParameterSummary { Summary("\(\.$tool) on \(\.$text)") }

    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: tool.apply(text)) }
}

struct CountWordsIntent: AppIntent {
    static let title: LocalizedStringResource = "Count Words"
    static let description = IntentDescription("Returns how many words some text has.")

    @Parameter(title: "Text", inputOptions: String.IntentInputOptions(multiline: true)) var text: String

    static var parameterSummary: some ParameterSummary { Summary("Count words in \(\.$text)") }

    func perform() async throws -> some IntentResult & ReturnsValue<Int> { .result(value: Stats(text).words) }
}
