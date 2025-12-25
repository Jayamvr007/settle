//
//  UserHelper.swift
//  Settle
//
//  Utility to identify current logged-in user across the app
//

import Foundation
import FirebaseAuth

/// Centralized helper for current user detection and display name logic
struct UserHelper {
    
    /// Check if a member is the currently logged-in user
    static func isCurrentUser(_ member: Member) -> Bool {
        guard let currentUserName = Auth.auth().currentUser?.displayName else { return false }
        return member.name == currentUserName
    }
    
    /// Check if a name matches the logged-in user
    static func isCurrentUserName(_ name: String) -> Bool {
        guard let currentUserName = Auth.auth().currentUser?.displayName else { return false }
        return name == currentUserName
    }
    
    /// Returns "You" if member is current user, otherwise returns member's name
    static func displayName(for member: Member) -> String {
        isCurrentUser(member) ? "You" : member.name
    }
    
    /// Returns "You" if name matches current user, otherwise returns the name
    static func displayName(for name: String) -> String {
        isCurrentUserName(name) ? "You" : name
    }
    
    /// Get the current user's display name from Firebase
    static var currentUserName: String? {
        Auth.auth().currentUser?.displayName
    }
}
