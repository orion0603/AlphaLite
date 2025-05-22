import SwiftUI
import Foundation

class SettingsManager: ObservableObject {
    @Published var notificationsEnabled: Bool = true
    @Published var voiceEnabled: Bool = true
    @Published var selectedVoice: String = "com.apple.ttsbundle.Daniel-compact"
    @Published var speechRate: Float = 0.5
    @Published var autoScroll: Bool = true
    @Published var messageHistoryLimit: Int = 100
    
    let availableVoices: [String] = [
        "com.apple.ttsbundle.Daniel-compact",
        "com.apple.ttsbundle.Samantha-compact",
        "com.apple.ttsbundle.Karen-compact"
    ]
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
    }
    
    func toggleVoice() {
        voiceEnabled.toggle()
    }
    
    func setVoice(_ identifier: String) {
        selectedVoice = identifier
    }
    
    func setSpeechRate(_ rate: Float) {
        speechRate = rate
    }
} 