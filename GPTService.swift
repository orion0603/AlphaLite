import Foundation
import OpenAI

class GPTService: ObservableObject {
    private var openAI: OpenAI?
    @Published var isOnline = true
    
    init() {
        setupOpenAI()
    }
    
    private func setupOpenAI() {
        do {
            let apiKey = try KeychainHelper.shared.getAPIKey()
            openAI = OpenAI(apiToken: apiKey)
        } catch {
            isOnline = false
        }
    }
    
    func chat(messages: [Chat.Message], memories: [String]) async throws -> String {
        guard isOnline, let openAI = openAI else {
            throw GPTError.offline
        }
        
        var systemMessage = "You are AlphaLite, a private on-device assistant."
        if !memories.isEmpty {
            systemMessage += "\n\nMEMORY:\n" + memories.joined(separator: "\n")
        }
        
        var chatMessages = [Chat.Message(role: .system, content: systemMessage)]
        chatMessages.append(contentsOf: messages)
        
        let query = ChatQuery(
            model: .gpt4,
            messages: chatMessages,
            functions: [
                ChatFunctionDeclaration(
                    name: "schedule_reminder",
                    description: "Schedule a reminder for a specific time",
                    parameters: [
                        "when_iso": .string(description: "ISO 8601 timestamp"),
                        "text": .string(description: "Reminder text"),
                        "critical": .boolean(description: "Whether this is a critical reminder")
                    ]
                ),
                ChatFunctionDeclaration(
                    name: "add_memory",
                    description: "Add a sentence to long-term memory",
                    parameters: [
                        "sentence": .string(description: "The sentence to remember")
                    ]
                )
            ]
        )
        
        let response = try await openAI.chats(query: query)
        return response.choices.first?.message.content ?? ""
    }
    
    func getEmbedding(for text: String) async throws -> [Double] {
        guard isOnline, let openAI = openAI else {
            throw GPTError.offline
        }
        
        let query = EmbeddingsQuery(
            model: .textEmbedding3Small,
            input: text
        )
        
        let response = try await openAI.embeddings(query: query)
        return response.data.first?.embedding ?? []
    }
}

enum GPTError: Error {
    case offline
} 