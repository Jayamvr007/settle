//
//  SettingsView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  SettingsView.swift
//  Settle
//

// ... existing imports ...
import SwiftUI
import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userUPI") private var userUPI: String = ""
    @State private var upiError: String?
    private var googleUser: User? {
        Auth.auth().currentUser
    }
    
    private var isGoogleSignedIn: Bool {
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
                                    Text(user.displayName ?? "Google user")
                                        .font(.headline)

                                    if let email = user.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Text("Signed in with Google")
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
                        Text("All data is stored locally on your device. There is no analytics, tracking, or third‑party data sharing. UPI payments are handled by your installed UPI apps.")
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
                
                if isGoogleSignedIn {
                    Section("Account") {
                        Button(role: .destructive) {
                            signOutFromGoogle()
                        } label: {
                            Text("Sign out of Google")
                        }
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
                    // If you want, you can also prefill phone from Firebase if present:
                    // if userPhone.isEmpty, and user.phoneNumber != nil { userPhone = user.phoneNumber! }
                    // UPI ID should stay manual, since Google doesn't know it.
                }
            }
        }
    }
    
    private func clearAllData() {
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        // Delete all groups (cascade will delete everything)
        let fetchRequest = CDGroup.fetchRequest()
        if let groups = try? context.fetch(fetchRequest) {
            for group in groups {
                context.delete(group)
            }
            dataManager.save()
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
    private func signOutFromGoogle() {
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
            } catch {
                print("Failed to sign out: \(error.localizedDescription)")
            }
        }
}
