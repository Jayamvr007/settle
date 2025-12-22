//
//  SettleApp.swift
//  Settle
//


import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct SettleApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var groupRepository = GroupRepository()
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingUPIPrompt = false
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if let error = dataManager.loadError {
                    ContentUnavailableView(
                        "Database Error",
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text("Failed to load application data: \(error.localizedDescription)")
                    )
                } else {
                    ContentView()
                .environment(\.managedObjectContext, dataManager.context)
                .environmentObject(groupRepository)
                .environmentObject(authManager)
                        .onOpenURL { url in
                            handleIncomingURL(url)
                        }
                        .environmentObject(authManager)
                }
            }
            .environmentObject(authManager)
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
