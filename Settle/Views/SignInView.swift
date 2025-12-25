//
//  SignInView.swift
//  Settle
//
//  Created by Jayam Verma on 16/12/25.
//

import SwiftUI
import GoogleSignIn

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Logo/Icon
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.primaryGradient)
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome to Settle")
                    .font(.settleTitle)
                
                Text("Split expenses with friends")
                    .font(.settleBody)
                    .foregroundColor(.secondary)
            }
            
            // Google Sign-In (Google's official button)
            VStack(spacing: 16) {
                GoogleSignInButton(action: handleGoogleSignIn)
                    .frame(height: 50)
                    .padding(.horizontal, 32)
                    .opacity(isSigningIn ? 0.5 : 1.0)
                    .disabled(isSigningIn)
                    .overlay {
                        if isSigningIn {
                            ProgressView()
                                .tint(AppTheme.primary)
                        }
                    }
                
                if !authManager.errorMessage.isEmpty {
                    Text(authManager.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Privacy note
            Text("Your data stays private and secure")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
        }
        .padding()
    }
    
    private func handleGoogleSignIn() {
        isSigningIn = true
        Task {
            let success = await authManager.signInWithGoogle()
            isSigningIn = false
            if !success {
                print("Sign-in failed")
            }
        }
    }
}

// MARK: - Google Sign-In Button Wrapper
struct GoogleSignInButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.colorScheme = .light
        button.style = .wide
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }
        @objc func buttonTapped() { action() }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationManager())
}
