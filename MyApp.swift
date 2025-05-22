import SwiftUI

@main
struct MyApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
} 