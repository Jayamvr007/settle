//
//  HapticManager.swift
//  Settle
//
//  Provides tactile feedback for a premium feel.
//

import UIKit

enum HapticManager {
    
    /// Light impact feedback - for subtle interactions like button taps
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Medium impact feedback - for confirmations
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Heavy impact feedback - for major actions
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    /// Success notification - for successful operations
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Error notification - for failed operations
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    /// Warning notification - for alerts
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    /// Selection changed - for pickers and toggles
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
