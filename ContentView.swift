import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var gptService = GPTService()
    @StateObject private var memoryStore: MemoryStore
    @StateObject private var reminderStore = ReminderStore()
    
    @State private var messages: [Chat.Message] = []
    @State private var apiKey = ""
    @State private var showingAPIKeyPrompt = false
    @State private var isProcessing = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        let gpt = GPTService()
        _memoryStore = StateObject(wrappedValue: MemoryStore(gptService: gpt))
    }
    
    var body: some View {
        VStack {
            if showingAPIKeyPrompt {
                apiKeyPrompt
            } else {
                mainContent
            }
        }
        .onAppear {
            showingAPIKeyPrompt = !KeychainHelper.shared.hasAPIKey()
        }
    }
    
    private var apiKeyPrompt: some View {
        VStack {
            Text("Enter OpenAI API Key")
                .font(.title)
            
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Save") {
                do {
                    try KeychainHelper.shared.saveAPIKey(apiKey)
                    showingAPIKeyPrompt = false
                    gptService.setupOpenAI()
                } catch {
                    print("Failed to save API key: \(error.localizedDescription)")
                }
            }
            .disabled(apiKey.isEmpty)
        }
        .padding()
    }
    
    private var mainContent: some View {
        VStack {
            micButton
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.self) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            upcomingReminders
        }
    }
    
    private var micButton: some View {
        Button {
            if speechManager.isRecording {
                speechManager.stopRecording()
                processSpeech()
            } else {
                try? speechManager.startRecording()
            }
        } label: {
            Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(speechManager.isRecording ? .red : .blue)
        }
        .padding()
        .accessibilityLabel(speechManager.isRecording ? "Stop Recording" : "Start Recording")
    }
    
    private var upcomingReminders: some View {
        List {
            ForEach(reminderStore.getUpcomingReminders(), id: \.id) { reminder in
                VStack(alignment: .leading) {
                    Text(reminder.text ?? "")
                        .font(.headline)
                    Text(reminder.when?.formatted() ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(height: 200)
    }
    
    private func processSpeech() {
        guard !speechManager.transcribedText.isEmpty else { return }
        
        let userMessage = Chat.Message(role: .user, content: speechManager.transcribedText)
        messages.append(userMessage)
        
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let memories = try await memoryStore.findSimilarMemories(to: speechManager.transcribedText)
                let response = try await gptService.chat(messages: messages, memories: memories)
                
                let assistantMessage = Chat.Message(role: .assistant, content: response)
                messages.append(assistantMessage)
                
                speakResponse(response)
            } catch {
                let errorMessage = Chat.Message(role: .assistant, content: "I'm offline. Please check your internet connection.")
                messages.append(errorMessage)
                speakResponse("I'm offline. Please check your internet connection.")
            }
        }
    }
    
    private func speakResponse(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Daniel-compact")
        synthesizer.speak(utterance)
    }
}

struct MessageBubble: View {
    let message: Chat.Message
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.role == .assistant ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(message.role == .assistant ? .white : .primary)
                .cornerRadius(16)
            
            if message.role == .user {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
} 