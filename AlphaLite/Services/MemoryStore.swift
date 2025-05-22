import Foundation
import CoreData
import Accelerate

class MemoryStore: ObservableObject {
    @Published private(set) var chatThreads: [ChatThread] = []
    @Published private(set) var analytics: Analytics = Analytics()
    private let gptService: GPTService
    private let container: NSPersistentContainer
    @Published var memories: [Memory] = []
    
    init(gptService: GPTService) {
        self.gptService = gptService
        
        container = NSPersistentContainer(name: "AlphaLite")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        loadChatThreads()
        loadAnalytics()
    }
    
    // MARK: - Chat Thread Management
    
    func createNewThread(title: String, tags: [String] = []) -> ChatThread {
        let thread = ChatThread(title: title, tags: tags)
        chatThreads.append(thread)
        saveChatThreads()
        return thread
    }
    
    func addMessage(_ message: Chat.Message, to thread: ChatThread) {
        if let index = chatThreads.firstIndex(where: { $0.id == thread.id }) {
            var updatedThread = thread
            updatedThread.addMessage(message)
            chatThreads[index] = updatedThread
            saveChatThreads()
            
            // Track message in analytics
            analytics.trackMessage(message)
        }
    }
    
    func deleteThread(_ thread: ChatThread) {
        chatThreads.removeAll { $0.id == thread.id }
        saveChatThreads()
    }
    
    // MARK: - Memory Management
    
    func addMemory(_ content: String) {
        let memory = Memory(context: container.viewContext)
        memory.id = UUID()
        memory.content = content
        memory.timestamp = Date()
        
        do {
            try container.viewContext.save()
            analytics.trackMemoryCreation()
        } catch {
            print("Failed to save memory: \(error.localizedDescription)")
        }
    }
    
    func findSimilarMemories(to query: String) async throws -> [Memory] {
        let queryEmbedding = try await gptService.getEmbedding(for: query)
        
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Memory> = Memory.fetchRequest()
        
        guard let memories = try? context.fetch(fetchRequest) else {
            return []
        }
        
        let similarities = memories.map { memory -> (Memory, Double) in
            guard let embedding = memory.embedding else { return (memory, 0) }
            let similarity = cosineSimilarity(queryEmbedding, embedding)
            return (memory, similarity)
        }
        
        return similarities
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .prefix(limit)
            .compactMap { $0.0.sentence }
    }
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        
        vDSP_dotprD(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_svesqD(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesqD(b, 1, &normB, vDSP_Length(b.count))
        
        normA = sqrt(normA)
        normB = sqrt(normB)
        
        return dotProduct / (normA * normB)
    }
} 