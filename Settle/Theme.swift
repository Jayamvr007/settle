//
//  Theme.swift
//  Settle
//
//  Design System: Colors, Typography, and Styles
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    
    // MARK: - Brand Colors (Blue Theme)
    static let primary = Color(hex: "007AFF")       // iOS System Blue
    static let primaryLight = Color(hex: "5AC8FA") // Light Blue
    static let secondary = Color(hex: "34C759")     // System Green
    static let accent = Color(hex: "FF9500")        // System Orange
    
    // MARK: - Semantic Colors
    static let owes = Color(hex: "FF3B30")          // System Red (for debts)
    static let getsBack = Color(hex: "34C759")      // System Green (for credits)
    static let warning = Color(hex: "FFCC00")       // System Yellow
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5AC8FA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let dangerGradient = LinearGradient(
        colors: [Color(hex: "FF3B30"), Color(hex: "FF6961")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Card Styles
    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.08)
    static let cardCornerRadius: CGFloat = 16
    
    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
}

// MARK: - Custom Fonts
extension Font {
    static let settleTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let settleHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let settleBody = Font.system(size: 15, weight: .regular)
    static let settleCaption = Font.system(size: 12, weight: .regular)
    static let settleAmount = Font.system(size: 22, weight: .bold, design: .rounded)
    static let settleLargeAmount = Font.system(size: 32, weight: .heavy, design: .rounded)
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Button Styles
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.settleHeadline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryGradient)
            .cornerRadius(AppTheme.cardCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.paddingMedium)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: AppTheme.cardShadow, radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
