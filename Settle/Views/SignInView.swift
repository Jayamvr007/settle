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
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Logo/Icon
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome to Settle")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Split expenses with friends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Google Sign-In Button
            VStack(spacing: 16) {
                GoogleSignInButton(action: handleSignIn)
                    .frame(height: 50)
                    .padding(.horizontal, 32)
                
                if isSigningIn {
                    ProgressView("Signing in...")
                        .tint(.blue)
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

#Preview {
    SignInView()
        .environmentObject(AuthenticationManager())
}
