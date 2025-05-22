import Foundation

struct Memory: Identifiable {
    let id: UUID
    var sentence: String
    var embedding: [Double]
} 