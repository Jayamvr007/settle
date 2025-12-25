//
//  ContentView.swift
//  Settle
//
//  Created by Jayam Verma on 13/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var isSignedIn: Bool = Auth.auth().currentUser != nil
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        rootView
        .onAppear {
            // Keep local state in sync with Firebase
            Auth.auth().addStateDidChangeListener { _, user in
                isSignedIn = (user != nil)
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else if !isSignedIn {
            SignInView()
        } else {
            mainTabs
        }
    }

    // MARK: - Main Tabs

    private var mainTabs: some View {
        TabView {
            GroupsListView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            BalancesView()
                .tabItem {
                    Label("Balances", systemImage: "indianrupeesign.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// MARK: - Helper to get key window for presenting Google Sign-In

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

#Preview {
    ContentView().environmentObject(GroupRepository.shared)
}
