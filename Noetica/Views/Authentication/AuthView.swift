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
    @State private var cardOffset: CGFloat = 300
    @State private var cardOpacity: Double = 0
    
    var body: some View {
        if authService.isAuthenticated {
            MainTabView()
                .environmentObject(authService)
        } else {
            GeometryReader { geometry in
                ZStack {
                    // Dynamic gradient background
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.05),
                            Color.indigo.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Floating elements
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: CGFloat.random(in: 60...120))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .blur(radius: 20)
                    }
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header section
                            VStack(spacing: 24) {
                                Spacer(minLength: 60)
                                
                                // Logo and title
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text(isLogin ? "Welcome Back" : "Join Noetica")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        Text(isLogin ? "Continue your learning journey" : "Start your learning adventure")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding(.bottom, 40)
                            
                            // Auth card
                            VStack(spacing: 24) {
                                VStack(spacing: 20) {
                                    ModernTextField(
                                        text: $email,
                                        placeholder: "Email address",
                                        icon: "envelope"
                                    )
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    
                                    if !isLogin {
                                        ModernTextField(
                                            text: $username,
                                            placeholder: "Username",
                                            icon: "person"
                                        )
                                        .autocapitalization(.none)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                    }
                                    
                                    ModernSecureField(
                                        text: $password,
                                        placeholder: "Password",
                                        icon: "lock"
                                    )
                                    
                                    if isLogin {
                                        HStack {
                                            Spacer()
                                            Button("Forgot Password?") {
                                                showForgotPassword = true
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                        }
                                        .transition(.opacity)
                                    }
                                }
                                
                                VStack(spacing: 16) {
                                    // Main action button
                                    Button(action: handleAuth) {
                                        HStack(spacing: 12) {
                                            if authService.isLoading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.9)
                                            } else {
                                                Image(systemName: isLogin ? "arrow.right.circle.fill" : "person.badge.plus.fill")
                                                    .font(.system(size: 18, weight: .semibold))
                                                
                                                Text(isLogin ? "Sign In" : "Create Account")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            LinearGradient(
                                                colors: isValidForm ? [Color.blue, Color.blue.opacity(0.8)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .shadow(
                                            color: isValidForm ? Color.blue.opacity(0.3) : Color.clear,
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                    }
                                    .disabled(!isValidForm || authService.isLoading)
                                    .scaleEffect(authService.isLoading ? 0.98 : 1.0)
                                    .animation(.easeInOut(duration: 0.1), value: authService.isLoading)
                                    
                                    // Toggle mode button
                                    Button(action: toggleMode) {
                                        HStack(spacing: 8) {
                                            Text(isLogin ? "New to Noetica?" : "Already have an account?")
                                                .foregroundColor(.secondary)
                                            
                                            Text(isLogin ? "Sign Up" : "Sign In")
                                                .foregroundColor(.blue)
                                                .fontWeight(.semibold)
                                        }
                                        .font(.system(size: 15, weight: .medium))
                                    }
                                }
                                
                                // Error message
                                if !authService.errorMessage.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: authService.errorMessage.contains("successfully") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .foregroundColor(authService.errorMessage.contains("successfully") ? .green : .red)
                                        
                                        Text(authService.errorMessage)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(authService.errorMessage.contains("successfully") ? .green : .red)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(authService.errorMessage.contains("successfully") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            )
                            .padding(.horizontal, 20)
                            .offset(y: cardOffset)
                            .opacity(cardOpacity)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                    cardOffset = 0
                    cardOpacity = 1
                }
            }
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

struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .blue : .secondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .focused($isFocused)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.blue : Color(.systemGray4), lineWidth: isFocused ? 2 : 1)
                )
        )
        .shadow(color: isFocused ? Color.blue.opacity(0.1) : Color.black.opacity(0.05), radius: isFocused ? 8 : 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct ModernSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState private var isFocused: Bool
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .blue : .secondary)
                .frame(width: 20)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .focused($isFocused)
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.blue : Color(.systemGray4), lineWidth: isFocused ? 2 : 1)
                )
        )
        .shadow(color: isFocused ? Color.blue.opacity(0.1) : Color.black.opacity(0.05), radius: isFocused ? 8 : 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthService())
    }
}
