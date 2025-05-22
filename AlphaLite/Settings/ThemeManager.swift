import SwiftUI
import Foundation

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme? = .light
    @Published var accentColor: Color = .blue
    @Published var backgroundColor: Color = Color(.systemBackground)
    @Published var textColor: Color = Color(.label)
    
    let availableAccentColors: [Color] = [.blue, .purple, .pink, .orange, .green]
    
    func toggleColorScheme() {
        colorScheme = colorScheme == .dark ? .light : .dark
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
    }
} 