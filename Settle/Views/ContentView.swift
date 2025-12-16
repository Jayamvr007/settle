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
    @State private var isSigningIn = false
    @State private var signInError: String?

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
            googleSignInScreen
        } else {
            mainTabs
        }
    }

    // MARK: - Main Tabs (your existing app)

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

    // MARK: - Google Sign-In Screen

    private var googleSignInScreen: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 72))
                    .foregroundColor(.blue)

                Text("Sign in to continue")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Use your Google account to keep your profile in sync on this device. Your expense data still stays local on your iPhone.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let signInError {
                    Text(signInError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: signInWithGoogle) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        Text(isSigningIn ? "Signing in..." : "Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isSigningIn ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isSigningIn)
                .padding(.horizontal)

                Button("Continue without sign in") {
                    // Optional: allow skipping sign-in
                    isSignedIn = true
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

                Spacer()
            }
            .navigationTitle("Welcome to Settle")
        }
    }

    // MARK: - Google Sign-In Logic

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            signInError = "Missing Firebase client ID"
            return
        }

        isSigningIn = true
        signInError = nil

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootViewController = UIApplication.shared.firstKeyWindow?.rootViewController else {
            signInError = "Unable to get root view controller"
            isSigningIn = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                self.signInError = error.localizedDescription
                self.isSigningIn = false
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.signInError = "Google sign-in failed"
                self.isSigningIn = false
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)

            Auth.auth().signIn(with: credential) { _, error in
                self.isSigningIn = false

                if let error = error {
                    self.signInError = error.localizedDescription
                    return
                }

                // Success
                self.isSignedIn = true
            }
        }
    }
}

// MARK: - Helper to get key window for presenting Google Sign-In

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        // Supports multi-scene apps
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}


#Preview {
    ContentView().environmentObject(GroupRepository())
}
