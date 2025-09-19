//
//  AuthService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-16.
//



import Foundation
import FirebaseAuth
import SwiftUI

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signUp(email: String, password: String, username: String) {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("Trying to create account for: \(email)")
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    let nsError = error as NSError
                    print("Firebase error: \(nsError.localizedDescription)")
                    print("Error code: \(nsError.code)")
                    
                    switch AuthErrorCode(rawValue: nsError.code) {
                    case .emailAlreadyInUse:
                        self?.errorMessage = "This email is already registered"
                    case .invalidEmail:
                        self?.errorMessage = "Invalid email address format"
                    case .weakPassword:
                        self?.errorMessage = "Password is too weak"
                    case .networkError:
                        self?.errorMessage = "Network error - check your internet connection"
                    case .internalError:
                        self?.errorMessage = "Service temporarily unavailable. Please check Firebase configuration."
                    default:
                        self?.errorMessage = "Failed to create account: \(error.localizedDescription)"
                    }
                    return
                }
                
                if let user = result?.user {
                    print("Account created! User ID: \(user.uid)")
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = username
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Couldn't set username: \(error.localizedDescription)")
                        } else {
                            print("Username set to: \(username)")
                        }
                    }
                }
                
                self?.errorMessage = "Account created successfully!"
            }
        }
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                self?.errorMessage = "Signed in successfully!"
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            errorMessage = ""
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    func resetPassword(email: String) {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = "Password reset email sent!"
                }
            }
        }
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }
    
    var userDisplayName: String {
        return user?.displayName ?? user?.email?.components(separatedBy: "@").first ?? "User"
    }
    
    var userEmail: String {
        return user?.email ?? ""
    }
}

extension AuthService {
    func updateDisplayName(to newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."])) )
            return
        }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            user.reload { reloadError in
                DispatchQueue.main.async {
                    if let reloadError = reloadError {
                        completion(.failure(reloadError))
                    } else {
                        self?.user = Auth.auth().currentUser
                        completion(.success(()))
                    }
                }
            }
        }
    }
}
