import Foundation
import OpenAI

class GPTService {
    let client = OpenAI(apiToken: "") // Replace with Keychain fetch
    // Add async GPT call stubs here
}

enum GPTError: Error {
    case offline
} 