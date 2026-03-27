//
//  SettingsView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userUPI") private var userUPI: String = ""
    @State private var upiError: String?
    @State private var showDeleteConfirmation = false
    @State private var isDeletingAccount = false
    
    private var googleUser: User? {
        Auth.auth().currentUser
    }
    
    private var isSignedIn: Bool {
        googleUser != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Your Profile") {
                    if let user = googleUser {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.primary)
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName ?? "User")
                                    .font(.headline)

                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("Signed in")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    TextField("Your Name", text: $userName)
                        .autocorrectionDisabled()
                    
                    TextField("UPI ID", text: $userUPI)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    if let upiError {
                        Text(upiError)
                            .font(.caption)
                            .foregroundColor(AppTheme.owes)
                    }
                }
                
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Legal") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Privacy Policy")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Your data syncs securely via Firebase. We do not sell your data, track you for ads, or share data with third parties. UPI links open your installed UPI apps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Terms of Use")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Use this app at your own discretion to help track shared expenses. Payment execution and verification are handled by external UPI apps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if isSignedIn {
                    Section {
                        Button(role: .destructive) {
                            authManager.signOut()
                        } label: {
                            Text("Sign Out")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                if isDeletingAccount {
                                    ProgressView()
                                        .tint(.red)
                                    Text("Deleting Account...")
                                        .foregroundColor(.red)
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Account")
                                }
                            }
                        }
                        .disabled(isDeletingAccount)
                    } header: {
                        Text("Account")
                    } footer: {
                        Text("Deleting your account will permanently remove all your groups, expenses, and personal data. This action cannot be undone.")
                    }
                }
                
            }
            .navigationTitle("Settings")
            .onChange(of: userUPI) {
                validateUPI()
            }
            .onAppear {
                if let user = googleUser {
                    if userName.isEmpty {
                        userName = user.displayName ?? userName
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Permanently", role: .destructive) {
                    isDeletingAccount = true
                    Task {
                        let success = await authManager.deleteAccount()
                        isDeletingAccount = false
                        if !success {
                            // Error is shown via authManager.errorMessage
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account, all groups, expenses, and personal data. This cannot be undone.")
            }
        }
    }
    
    private func validateUPI() {
        guard !userUPI.isEmpty else {
            upiError = nil
            return
        }
        
        let trimmed = userUPI.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(" ") || !trimmed.contains("@") {
            upiError = "UPI ID looks invalid (e.g. name@bank or 9876543210@ybl)"
        } else {
            upiError = nil
        }
    }
}
