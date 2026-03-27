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
import AuthenticationServices
import CryptoKit

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
    @Published var verificationID: String? = nil
    
    // Apple Sign-In nonce
    private var currentNonce: String?
    
    init() {
        registerAuthStateHandler()
    }
    
    private func registerAuthStateHandler() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.authenticationState = user != nil ? .authenticated : .unauthenticated
        }
    }
    
    // MARK: - Apple Sign-In
    
    /// Generate a random nonce for Apple Sign-In security
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    /// SHA256 hash of the nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Start Apple Sign-In flow — returns the request for ASAuthorizationController
    func createAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }
    
    /// Handle the Apple Sign-In result
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> Bool {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unable to get Apple ID credential"
                return false
            }
            
            guard let nonce = currentNonce else {
                errorMessage = "Invalid state: nonce was not set"
                return false
            }
            
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to get identity token"
                return false
            }
            
            authenticationState = .authenticating
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            do {
                let result = try await Auth.auth().signIn(with: credential)
                
                // Apple only sends name on first sign-in, so update profile if available
                if let fullName = appleIDCredential.fullName {
                    let displayName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    
                    if !displayName.isEmpty {
                        let changeRequest = result.user.createProfileChangeRequest()
                        changeRequest.displayName = displayName
                        try? await changeRequest.commitChanges()
                    }
                }
                
                self.user = result.user
                authenticationState = .authenticated
                return true
                
            } catch {
                print("❌ Apple Sign-In Firebase Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                authenticationState = .unauthenticated
                return false
            }
            
        case .failure(let error):
            // User cancelled is not a real error
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return false
            }
            print("❌ Apple Sign-In Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return false
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
    
    // MARK: - Phone Number Auth
    
    func sendOTP(to phoneNumber: String, completion: @escaping (Bool, String?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false, nil)
                return
            }
            self.verificationID = verificationID
            completion(true, verificationID)
        }
    }

    func verifyOTP(_ otp: String, completion: @escaping (Bool) -> Void) {
        guard let verificationID = verificationID else {
            completion(false)
            return
        }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            self.user = result?.user
            self.authenticationState = .authenticated
            completion(true)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            authenticationState = .unauthenticated
            user = nil
            verificationID = nil
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Account
    
    /// Permanently deletes the user's account and all associated data.
    /// Required by Apple Guideline 5.1.1(v).
    func deleteAccount() async -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user signed in"
            return false
        }
        
        do {
            // 1. Delete all Firestore data first
            try await FirestoreService.shared.deleteAllUserData()
            
            // 2. Clear local data
            GroupRepository.shared.groups = []
            UserDefaults.standard.removeObject(forKey: "userName")
            UserDefaults.standard.removeObject(forKey: "userPhone")
            UserDefaults.standard.removeObject(forKey: "userUPI")
            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
            
            // 3. Delete Firebase Auth account
            try await currentUser.delete()
            
            // 4. Sign out
            GIDSignIn.sharedInstance.signOut()
            authenticationState = .unauthenticated
            user = nil
            
            return true
        } catch {
            print("❌ Account deletion error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - User Info
    
    var userName: String {
        // Try displayName first (Google Sign-In or Apple Sign-In)
        if let displayName = user?.displayName, !displayName.isEmpty {
            return displayName
        }
        // Fallback to phone number (Phone Auth)
        if let phone = user?.phoneNumber, !phone.isEmpty {
            return phone
        }
        // Fallback to email prefix
        if let email = user?.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "User"
        }
        return "User"
    }
    
    var userEmail: String {
        user?.email ?? ""
    }
    
    var userPhotoURL: URL? {
        user?.photoURL
    }
}
