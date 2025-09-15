//
//  AuthView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @State private var isLogin = true
    @State private var username = ""
    @State private var password = ""
    @State private var showBiometricOption = false
    @State private var authMessage = ""
    @State private var isAuthenticated = false

    var body: some View {
        NavigationView {
            if isAuthenticated {
                MainTabView()
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Text(isLogin ? "Login to Noetica" : "Sign Up to Noetica")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.blue)

                    VStack(spacing: 16) {
                        CustomTextField(text: $username, placeholder: "Username", imageName: "person.fill")
                            .autocapitalization(.none)

                        CustomSecureField(text: $password, placeholder: "Password", imageName: "lock.fill")
                    }

                    if showBiometricOption && isLogin {
                        Button(action: authenticateWithBiometrics) {
                            HStack {
                                Image(systemName: "faceid")
                                    .font(.title2)
                                Text("Login with Face ID / Touch ID")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                        .padding(.top, 12)
                    }

                    Button(action: handleAuth) {
                        Text(isLogin ? "Log In" : "Sign Up")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((username.isEmpty || password.isEmpty) ? Color.gray.opacity(0.5) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .disabled(username.isEmpty || password.isEmpty)

                    Button(action: {
                        isLogin.toggle()
                        authMessage = ""
                    }) {
                        Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }

                    if !authMessage.isEmpty {
                        Text(authMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                }
                .padding()
                .onAppear {
                    evaluateBiometricSupport()
                }
                .navigationTitle("")
                .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) 
    }

    private func evaluateBiometricSupport() {
        let context = LAContext()
        var error: NSError?
        showBiometricOption = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        let reason = "Log in to Noetica using biometrics"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    authMessage = "Biometric Authentication Successful"
                    isAuthenticated = true
                } else {
                    authMessage = "Biometric Authentication Failed"
                }
            }
        }
    }

    private func handleAuth() {
        authMessage = isLogin ? "Logged in successfully!" : "Signed up successfully!"
        isAuthenticated = true
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let imageName: String

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(Color.blue)
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
                .foregroundColor(Color.blue)
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
    }
}
