import Foundation

struct ChatThread: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Chat.Message]
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    
    init(id: UUID = UUID(), title: String, messages: [Chat.Message] = [], tags: [String] = []) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
    }
    
    mutating func addMessage(_ message: Chat.Message) {
        messages.append(message)
        updatedAt = Date()
    }
    
    var summary: String {
        if let firstMessage = messages.first {
            return firstMessage.content.prefix(50) + "..."
        }
        return "Empty conversation"
    }
} 