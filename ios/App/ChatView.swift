// Chat about the open file. The Mac asks Ollama on localhost; iPhone and iPad ask Apple's on-device model.
// ponytail: no streaming, one request at a time, no persistence. Add if needed.

import SwiftUI
import Foundation
#if os(iOS)
import FoundationModels
#endif

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatView: View {
    @Binding var document: TextDocument
    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var sending = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            Text("Agent")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.bar)
            #endif

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { msg in
                            HStack(spacing: 8) {
                                if msg.isUser {
                                    Spacer()
                                    Text(msg.text)
                                        .padding(8)
                                        .background(.blue)
                                        .foregroundStyle(.white)
                                        .cornerRadius(6)
                                } else {
                                    Text(msg.text)
                                        .padding(8)
                                        .background(.gray.opacity(0.2))
                                        .cornerRadius(6)
                                    Spacer()
                                }
                            }
                            .id(msg.id)
                        }
                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(8)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: messages.count) { proxy.scrollTo(messages.last?.id) }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Message...", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .disabled(sending)

                Button(action: send) {
                    Image(systemName: sending ? "ellipsis" : "paperplane.fill")
                }
                .disabled(sending || input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(8)
        }
        #if os(macOS)
        .frame(minHeight: 120, maxHeight: 300)
        #endif
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        input = ""
        messages.append(Message(text: text, isUser: true))
        error = nil
        sending = true

        Task {
            defer { sending = false }
            do {
                let context = "Current file: \(document.type.preferredFilenameExtension ?? "txt")\n\n\(document.text.prefix(2000))"
                #if os(iOS)
                let reply = try await Self.onDevice(context: context, question: text)
                #else
                let reply = try await Complete.fill(prefix: context + "\n\nUser: " + text, suffix: "")
                #endif
                messages.append(Message(text: reply.trimmingCharacters(in: .whitespaces), isUser: false))
            } catch {
                self.error = (error as? LocalizedError)?.errorDescription ?? "Failed to get response"
            }
        }
    }

    #if os(iOS)
    struct Unavailable: LocalizedError {
        var errorDescription: String? { "Chat needs Apple Intelligence turned on in Settings." }
    }

    static func onDevice(context: String, question: String) async throws -> String {
        guard case .available = SystemLanguageModel.default.availability else { throw Unavailable() }
        let session = LanguageModelSession(instructions: "You help with the file open in a plain text editor. Answer briefly and plainly.")
        return try await session.respond(to: context + "\n\nQuestion: " + question).content
    }
    #endif
}
