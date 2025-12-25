//
//  SettleApp.swift
//  Settle
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct SettleApp: App {
    @StateObject private var groupRepository = GroupRepository.shared
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(groupRepository)
                .environmentObject(authManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }
        
        // Handle UPI callback
        if url.scheme == "settle" && url.host == "upi-callback" {
            let status = UPIManager.shared.handleCallback(url: url)
            UPIManager.shared.lastTransactionStatus = status
            
            NotificationCenter.default.post(
                name: NSNotification.Name("UPIPaymentCallback"),
                object: status
            )
        }
    }
}
