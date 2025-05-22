import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var gptService = GPTService()
    @StateObject private var memoryStore: MemoryStore
    @StateObject private var reminderStore = ReminderStore()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsManager: SettingsManager
    
    @State private var messages: [Chat.Message] = []
    @State private var apiKey = ""
    @State private var showingAPIKeyPrompt = false
    @State private var isProcessing = false
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var showingReminderSheet = false
    @State private var newReminderText = ""
    @State private var newReminderDate = Date()
    @State private var typedMessage = ""
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var messageToDelete: Chat.Message?
    @State private var currentThread: ChatThread?
    @State private var newThreadTitle = ""
    @State private var newThreadTags = ""
    @State private var showingThreadSheet = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        let gpt = GPTService()
        _memoryStore = StateObject(wrappedValue: MemoryStore(gptService: gpt))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            mainChatView
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(0)
            
            remindersView
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(1)
            
            memoriesView
                .tabItem {
                    Label("Memories", systemImage: "brain.head.profile")
                }
                .tag(2)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .sheet(isPresented: $showingAPIKeyPrompt) {
            apiKeyPrompt
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingReminderSheet) {
            reminderSheet
        }
        .sheet(isPresented: $showingThreadSheet) {
            threadSheet
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Delete Message", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let message = messageToDelete,
                   let index = messages.firstIndex(of: message) {
                    withAnimation {
                        messages.remove(at: index)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
        .onAppear {
            showingAPIKeyPrompt = !KeychainHelper.shared.hasAPIKey()
        }
    }
    
    private var mainChatView: some View {
        NavigationView {
            VStack {
                if let currentThread = currentThread {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(currentThread.messages, id: \.self) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                        .onLongPressGesture {
                                            messageToDelete = message
                                            showingDeleteConfirmation = true
                                        }
                                }
                            }
                            .padding()
                        }
                        .onChange(of: currentThread.messages.count) { _ in
                            if settingsManager.autoScroll {
                                withAnimation {
                                    proxy.scrollTo(currentThread.messages.last?.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                } else {
                    threadListView
                }
                
                VStack(spacing: 8) {
                    HStack {
                        TextField("Type a message", text: $typedMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isProcessing)
                        
                        Button {
                            sendMessage(text: typedMessage)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(typedMessage.isEmpty ? .gray : themeManager.accentColor)
                        }
                        .disabled(typedMessage.isEmpty || isProcessing)
                        .accessibilityLabel("Send message")
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Button {
                            if speechManager.isRecording {
                                speechManager.stopRecording()
                                processSpeech()
                            } else {
                                try? speechManager.startRecording()
                            }
                        } label: {
                            Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(speechManager.isRecording ? .red : themeManager.accentColor)
                        }
                        .accessibilityLabel(speechManager.isRecording ? "Stop Recording" : "Start Recording")
                        .accessibilityHint("Double-tap and hold to record. Release to send.")
                        
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                                .accessibilityLabel("Processing message")
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(currentThread?.title ?? "Chats")
            .navigationBarItems(
                leading: currentThread != nil ? Button("Back") {
                    currentThread = nil
                } : nil,
                trailing: HStack {
                    if currentThread == nil {
                        Button {
                            showingThreadSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    settingsButton
                }
            )
        }
    }
    
    private var threadListView: some View {
        List {
            ForEach(memoryStore.chatThreads) { thread in
                Button {
                    currentThread = thread
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(thread.title)
                            .font(.headline)
                        Text(thread.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    memoryStore.deleteThread(memoryStore.chatThreads[index])
                }
            }
        }
    }
    
    private var remindersView: some View {
        NavigationView {
            List {
                Section(header: Text("Upcoming Reminders")) {
                    ForEach(reminderStore.getUpcomingReminders(), id: \.id) { reminder in
                        ReminderRow(reminder: reminder)
                    }
                    .onDelete(perform: deleteReminder)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarItems(trailing: addReminderButton)
        }
    }
    
    private var memoriesView: some View {
        NavigationView {
            List {
                ForEach(memoryStore.getAllMemories(), id: \.id) { memory in
                    MemoryRow(memory: memory)
                }
                .onDelete(perform: deleteMemory)
            }
            .navigationTitle("Memories")
        }
    }
    
    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gear")
        }
    }
    
    private var addReminderButton: some View {
        Button {
            showingReminderSheet = true
        } label: {
            Image(systemName: "plus")
        }
    }
    
    private var reminderSheet: some View {
        NavigationView {
            Form {
                TextField("Reminder", text: $newReminderText)
                DatePicker("When", selection: $newReminderDate)
            }
            .navigationTitle("New Reminder")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingReminderSheet = false
                },
                trailing: Button("Add") {
                    addReminder()
                    showingReminderSheet = false
                }
                .disabled(newReminderText.isEmpty)
            )
        }
    }
    
    private func addReminder() {
        let reminder = Reminder(text: newReminderText, when: newReminderDate)
        reminderStore.addReminder(reminder)
        newReminderText = ""
        newReminderDate = Date()
    }
    
    private func deleteReminder(at offsets: IndexSet) {
        reminderStore.deleteReminders(at: offsets)
    }
    
    private func deleteMemory(at offsets: IndexSet) {
        memoryStore.deleteMemories(at: offsets)
    }
    
    private func sendMessage(text: String) {
        guard !text.isEmpty else { return }
        
        let userMessage = Chat.Message(role: .user, content: text)
        withAnimation {
            if let thread = currentThread {
                memoryStore.addMessage(userMessage, to: thread)
            } else {
                messages.append(userMessage)
            }
        }
        typedMessage = ""
        
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let memories = try await memoryStore.findSimilarMemories(to: text)
                let response = try await gptService.chat(messages: messages, memories: memories)
                
                let assistantMessage = Chat.Message(role: .assistant, content: response)
                withAnimation {
                    if let thread = currentThread {
                        memoryStore.addMessage(assistantMessage, to: thread)
                    } else {
                        messages.append(assistantMessage)
                    }
                }
                
                if settingsManager.voiceEnabled {
                    speakResponse(response)
                }
            } catch {
                errorMessage = "Failed to process message: \(error.localizedDescription)"
                let errorMessage = Chat.Message(role: .assistant, content: "I'm offline. Please check your internet connection.")
                withAnimation {
                    if let thread = currentThread {
                        memoryStore.addMessage(errorMessage, to: thread)
                    } else {
                        messages.append(errorMessage)
                    }
                }
                if settingsManager.voiceEnabled {
                    speakResponse("I'm offline. Please check your internet connection.")
                }
            }
        }
    }
    
    private func processSpeech() {
        guard !speechManager.transcribedText.isEmpty else { return }
        sendMessage(text: speechManager.transcribedText)
    }
    
    private func speakResponse(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: settingsManager.selectedVoice)
        utterance.rate = settingsManager.speechRate
        synthesizer.speak(utterance)
    }
    
    private var threadSheet: some View {
        NavigationView {
            Form {
                TextField("Thread Title", text: $newThreadTitle)
                TextField("Tags (comma-separated)", text: $newThreadTags)
            }
            .navigationTitle("New Thread")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingThreadSheet = false
                },
                trailing: Button("Create") {
                    createNewThread()
                    showingThreadSheet = false
                }
                .disabled(newThreadTitle.isEmpty)
            )
        }
    }
    
    private func createNewThread() {
        let tags = newThreadTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        currentThread = memoryStore.createNewThread(
            title: newThreadTitle,
            tags: tags
        )
        
        newThreadTitle = ""
        newThreadTags = ""
    }
}

struct MessageBubble: View {
    let message: Chat.Message
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.role == .assistant ? themeManager.accentColor : Color(.systemGray5))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .foregroundColor(message.role == .assistant ? .white : .primary)
                .font(.system(.body, design: .rounded))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(message.role == .assistant ? "Assistant" : "You"): \(message.content)")
            
            if message.role == .user {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reminder.text ?? "")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            
            Text(reminder.when?.formatted() ?? "")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reminder: \(reminder.text ?? ""). Due: \(reminder.when?.formatted() ?? "")")
    }
}

struct MemoryRow: View {
    let memory: Memory
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(memory.content)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(memory.timestamp.formatted())
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memory: \(memory.content). Created: \(memory.timestamp.formatted())")
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(SettingsManager())
} 