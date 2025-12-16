//
//  AuthenticationState.swift
//  Settle
//
//  Created by Jayam Verma on 16/12/25.
//


//
//  AuthenticationManager.swift
//  Settle
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage = ""
    
    init() {
        registerAuthStateHandler()
    }
    
    private func registerAuthStateHandler() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.authenticationState = user != nil ? .authenticated : .unauthenticated
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error"
            return false
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            return false
        }
        
        do {
            authenticationState = .authenticating
            
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )
            
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                errorMessage = "ID token missing"
                authenticationState = .unauthenticated
                return false
            }
            
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: accessToken.tokenString
            )
            
            let result = try await Auth.auth().signIn(with: credential)
            self.user = result.user
            authenticationState = .authenticated
            return true
            
        } catch {
            print("❌ Google Sign-In Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            authenticationState = .unauthenticated
            user = nil
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - User Info
    
    var userName: String {
        user?.displayName ?? "User"
    }
    
    var userEmail: String {
        user?.email ?? ""
    }
    
    var userPhotoURL: URL? {
        user?.photoURL
    }
}
