//
//  SignInView.swift
//  Settle
//
//  Created by Jayam Verma on 16/12/25.
//


//
//  SignInView.swift
//  Settle
//

import SwiftUI
import GoogleSignIn

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Logo/Icon
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(AppTheme.primaryGradient)
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome to Settle")
                    .font(.settleTitle)
                
                Text("Split expenses with friends")
                    .font(.settleBody)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Google Sign-In Button
            VStack(spacing: 16) {
                // Using our custom wrapper
                GoogleSignInButton(action: handleSignIn)
                    .frame(height: 50)
                    .padding(.horizontal, 32)
                
                if isSigningIn {
                    ProgressView("Signing in...")
                        .tint(AppTheme.primary)
                }
                
                if !authManager.errorMessage.isEmpty {
                    Text(authManager.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Privacy note
            Text("Your data stays private and secure")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
        }
        .padding()
    }
    
    private func handleSignIn() {
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

// MARK: - Generic GIDSignInButton Wrapper
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
        
        @objc func buttonTapped() {
            action()
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationManager())
}
