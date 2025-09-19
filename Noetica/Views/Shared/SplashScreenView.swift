//
//  SplashScreenView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-19.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isLoading = true
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var particleOpacity: Double = 0.0
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.indigo.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(particleOpacity)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: particleOpacity
                    )
            }
            
            VStack(spacing: 40) {
                // Logo Section
                VStack(spacing: 20) {
                    // App Icon/Logo
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                        
                        // Main logo background
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        
                        // Logo icon
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App Name
                    VStack(spacing: 8) {
                        Text("Noetica")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("Smart Learning Companion")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.2)
                    }
                    .opacity(textOpacity)
                }
                
                // Loading indicator
                VStack(spacing: 16) {
                    // Custom loading animation
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 12, height: 12)
                                .scaleEffect(isLoading ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isLoading
                                )
                        }
                    }
                    .opacity(textOpacity)
                    
                    Text("Preparing your learning experience...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            startAnimations()
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showContent = true
                }
            }
        }
        .fullScreenCover(isPresented: $showContent) {
            AuthView()
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text animation with delay
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            textOpacity = 1.0
        }
        
        // Particles animation with delay
        withAnimation(.easeInOut(duration: 1.0).delay(0.8)) {
            particleOpacity = 1.0
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AuthService())
}
