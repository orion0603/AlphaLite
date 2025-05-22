import Foundation
import CoreData
import UserNotifications
import EventKit

class ReminderStore: ObservableObject {
    @Published private(set) var reminders: [Reminder] = []
    private let container: NSPersistentContainer
    private let eventStore = EKEventStore()
    private let dateParser = DateParser()
    
    init() {
        container = NSPersistentContainer(name: "AlphaLite")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        requestNotificationPermission()
        requestAccess()
        loadReminders()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleReminder(when: Date, text: String, critical: Bool) throws {
        let context = container.viewContext
        let reminder = Reminder(context: context)
        reminder.id = UUID()
        reminder.when = when
        reminder.text = text
        reminder.critical = critical
        
        try context.save()
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = text
        
        if critical {
            content.interruptionLevel = .critical
            content.sound = .defaultCritical
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: when)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: reminder.id?.uuidString ?? UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func getUpcomingReminders() -> [Reminder] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "when > %@", Date() as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.when, ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch reminders: \(error.localizedDescription)")
            return []
        }
    }
} 