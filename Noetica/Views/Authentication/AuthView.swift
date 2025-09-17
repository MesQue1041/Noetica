//
//  AuthView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var showBiometricOption = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(isLogin ? "Welcome Back" : "Join Noetica")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.blue)
                        
                        Text(isLogin ? "Sign in to continue your learning journey" : "Start your learning adventure")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 16) {
                        CustomTextField(
                            text: $email,
                            placeholder: "Email",
                            imageName: "envelope.fill"
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        
                        if !isLogin {
                            CustomTextField(
                                text: $username,
                                placeholder: "Username",
                                imageName: "person.fill"
                            )
                            .autocapitalization(.none)
                        }
                        
                        CustomSecureField(
                            text: $password,
                            placeholder: "Password",
                            imageName: "lock.fill"
                        )
                        
                        if isLogin {
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.footnote)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: handleAuth) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(isLogin ? "Sign In" : "Create Account")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidForm ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                        .disabled(!isValidForm || authService.isLoading)
                        
                        Button(action: toggleMode) {
                            Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(authService.errorMessage.contains("successfully") ? .green : .red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .font(.footnote)
                    }
                    
                    Spacer()
                }
                .padding()
                .alert("Reset Password", isPresented: $showForgotPassword) {
                    TextField("Enter your email", text: $email)
                    Button("Send Reset Email") {
                        authService.resetPassword(email: email)
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Enter your email address to receive a password reset link.")
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var isValidForm: Bool {
        if isLogin {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty && !username.isEmpty
        }
    }
    
    private func handleAuth() {
        if isLogin {
            authService.signIn(email: email, password: password)
        } else {
            authService.signUp(email: email, password: password, username: username)
        }
    }
    
    private func toggleMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLogin.toggle()
            authService.errorMessage = ""
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let imageName: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(.blue)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let imageName: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(.blue)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthService())
    }
}
