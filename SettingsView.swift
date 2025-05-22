import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: Binding(
                        get: { themeManager.colorScheme == .dark },
                        set: { _ in themeManager.toggleColorScheme() }
                    ))
                    
                    ColorPicker("Accent Color", selection: $themeManager.accentColor)
                }
                
                Section(header: Text("Voice Settings")) {
                    Toggle("Enable Voice", isOn: $settingsManager.voiceEnabled)
                    
                    Picker("Voice", selection: $settingsManager.selectedVoice) {
                        ForEach(settingsManager.availableVoices, id: \.self) { voice in
                            Text(voice.components(separatedBy: ".").last ?? voice)
                        }
                    }
                    .disabled(!settingsManager.voiceEnabled)
                    
                    VStack {
                        Text("Speech Rate")
                        Slider(value: $settingsManager.speechRate, in: 0.1...1.0)
                    }
                    .disabled(!settingsManager.voiceEnabled)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                }
                
                Section(header: Text("Chat Settings")) {
                    Toggle("Auto-scroll", isOn: $settingsManager.autoScroll)
                    
                    Stepper("Message History: \(settingsManager.messageHistoryLimit)", value: $settingsManager.messageHistoryLimit, in: 10...1000, step: 10)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(SettingsManager())
} 