# AlphaLite

A private, on-device iOS assistant powered by GPT-4 and local speech recognition.

## Features

- Press-and-hold microphone recording with offline speech recognition
- GPT-4 powered chat with function calling
- Reminder scheduling with critical alerts
- Long-term memory using vector embeddings
- Text-to-speech responses
- Secure API key storage
- Offline mode support

## Requirements

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later
- OpenAI API key

## Project Structure

- `ContentView.swift` - Main UI and interaction logic
- `SpeechManager.swift` - Handles speech recognition
- `GPTService.swift` - OpenAI API integration
- `MemoryStore.swift` - Core Data and vector search
- `ReminderStore.swift` - Reminder management
- `KeychainHelper.swift` - Secure API key storage
- `AlphaLite.xcdatamodeld` - Core Data model

## Build & Run Instructions

1. Enable Developer Mode on your iPhone:
   - Go to Settings > Privacy & Security
   - Scroll to Developer Mode
   - Toggle it on and restart your device

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/AlphaLite.git
   cd AlphaLite
   ```

3. Create a `.env` file in the project root:
   ```
   OPENAI_API_KEY=your_api_key_here
   ```

4. Open the project in Xcode:
   ```bash
   open AlphaLite.xcodeproj
   ```

5. Select your iPhone as the target device

6. Build and run (⌘R)

7. On first launch:
   - Enter your OpenAI API key in the secure text field
   - Grant microphone and notification permissions when prompted

8. Test the assistant:
   - Hold the microphone button and say "Remind me tomorrow at 7 am to stretch, critical"
   - Verify that the reminder appears in the list
   - Wait for the notification to fire

## Development Notes

- The app uses Core Data for local storage
- Speech recognition works offline using SFSpeechRecognizer
- Vector search uses Accelerate framework for efficient similarity calculations
- Critical reminders use UNNotificationPresentationOptions.criticalAlert
- API key is stored securely in the Keychain

## License

This project is available under the MIT license. #   A l p h a L i t e  
 