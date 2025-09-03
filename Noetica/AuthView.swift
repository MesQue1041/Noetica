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
                ContentView()
            } else {
                VStack(spacing: 20) {
                    Text(isLogin ? "Login to Noetica" : "Sign Up to Noetica")
                        .font(.largeTitle)
                        .bold()

                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if showBiometricOption && isLogin {
                        Button(action: authenticateWithBiometrics) {
                            Label("Login with Face ID / Touch ID", systemImage: "faceid")
                                .foregroundColor(.blue)
                        }
                    }

                    Button(action: handleAuth) {
                        Text(isLogin ? "Log In" : "Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(username.isEmpty || password.isEmpty)

                    Button(action: {
                        isLogin.toggle()
                        authMessage = ""
                    }) {
                        Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                            .font(.footnote)
                    }

                    if !authMessage.isEmpty {
                        Text(authMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding()
                .onAppear {
                    evaluateBiometricSupport()
                }
            }
        }
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

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
