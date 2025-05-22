import Foundation
import CoreData
import Accelerate

class MemoryStore: ObservableObject {
    private let container: NSPersistentContainer
    private let gptService: GPTService
    
    init(gptService: GPTService) {
        self.gptService = gptService
        
        container = NSPersistentContainer(name: "AlphaLite")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func addMemory(_ sentence: String) async throws {
        let embedding = try await gptService.getEmbedding(for: sentence)
        
        let context = container.viewContext
        let memory = Memory(context: context)
        memory.id = UUID()
        memory.sentence = sentence
        memory.embedding = embedding
        
        try context.save()
    }
    
    func findSimilarMemories(to query: String, limit: Int = 3) async throws -> [String] {
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