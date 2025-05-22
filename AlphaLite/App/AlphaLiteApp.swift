import SwiftUI

@main
struct AlphaLiteApp: App {
    @StateObject private var memoryStore = MemoryStore()
    @StateObject private var reminderStore = ReminderStore()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(memoryStore)
                .environmentObject(reminderStore)
                .environmentObject(settingsManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
} 