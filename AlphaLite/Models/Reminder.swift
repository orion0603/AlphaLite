import Foundation

struct Reminder: Identifiable {
    let id: UUID
    var when: Date
    var text: String
    var critical: Bool
    var title: String? { text }
    var scheduledDate: Date? { when }
} 