import SwiftUI

struct ContentView: View {
    @StateObject private var reminderStore = ReminderStore()
    @StateObject private var memoryStore = MemoryStore()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some View {
        TabView {
            RemindersView()
                .tabItem {
                    Label("Reminders", systemImage: "list.bullet")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(reminderStore)
        .environmentObject(memoryStore)
        .environmentObject(settingsManager)
    }
}

struct RemindersView: View {
    @EnvironmentObject var reminderStore: ReminderStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(reminderStore.reminders) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }
            .navigationTitle("Reminders")
        }
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(reminder.title ?? "")
                .font(.headline)
            if let date = reminder.scheduledDate {
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
