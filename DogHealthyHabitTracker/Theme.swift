import SwiftUI

enum DogTheme {
    // Primary Colors
    static let primaryGreen = Color(red: 0.16, green: 0.65, blue: 0.44)
    static let darkGreen = Color(red: 0.10, green: 0.45, blue: 0.30)
    static let softGreen = Color(red: 0.90, green: 0.97, blue: 0.93)
    
    static let primaryBlue = Color(red: 0.18, green: 0.52, blue: 0.89)
    static let darkBlue = Color(red: 0.12, green: 0.35, blue: 0.65)
    static let softBlue = Color(red: 0.91, green: 0.95, blue: 0.99)
    
    // Accent Colors
    static let accentOrange = Color(red: 0.98, green: 0.52, blue: 0.18)
    static let darkOrange = Color(red: 0.85, green: 0.40, blue: 0.10)
    static let softOrange = Color(red: 1.00, green: 0.94, blue: 0.88)
    
    // Gender Colors (Salmon Pink for Female)
    static let salmonPink = Color(red: 0.98, green: 0.48, blue: 0.53)
    static let softSalmonPink = Color(red: 1.00, green: 0.92, blue: 0.94)
    
    // Backgrounds & Neutrals
    static let pureWhite = Color.white
    static let backgroundWhite = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let subtleGray = Color(uiColor: .systemGray5)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    
    // Gradients
    static let greenBlueGradient = LinearGradient(
        colors: [primaryGreen, primaryBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let orangeGradient = LinearGradient(
        colors: [accentOrange, Color(red: 1.0, green: 0.65, blue: 0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let softHeaderGradient = LinearGradient(
        colors: [softGreen.opacity(0.7), softBlue.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
