# AlphaLite

AlphaLite is an iOS app that combines AI-powered chat, reminders, and memory management in a beautiful, accessible interface.

## Features

- 🤖 AI-powered chat with context awareness
- ⏰ Smart reminders with natural language support
- 💾 Conversation memory and threading
- 🎨 Beautiful, accessible UI with dark mode support
- 📊 Usage analytics and insights
- 🔒 Secure API key management

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- OpenAI API key

## Setup

1. Clone the repository
2. Create a `.env` file in the project root with your OpenAI API key:
   ```
   OPENAI_API_KEY=your_api_key_here
   ```
3. Run the post-build script to add the API key to Keychain:
   ```bash
   chmod +x Scripts/postBuild.sh
   ./Scripts/postBuild.sh
   ```
4. Open `AlphaLite.xcodeproj` in Xcode
5. Build and run the project

## Project Structure

```
AlphaLite/
├── AlphaLite.xcodeproj           ← Project configuration
├── AlphaLite.xcdatamodeld/       ← Core Data model
├── Package.swift                 ← Dependencies
├── Scripts/                      ← Build scripts
├── Resources/                    ← Assets and configuration
├── App/                          ← Main app files
├── Services/                     ← Business logic
├── Settings/                     ← App settings
└── Models/                       ← Data models
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 