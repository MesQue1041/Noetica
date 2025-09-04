//
//  SettingsView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showAccountSettings = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode")
                    }
                }
                Section {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account Settings", systemImage: "person.crop.circle")
                    }
                    NavigationLink(destination: AboutView()) {
                        Label("About Noetica", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AccountSettingsView: View {
    var body: some View {
        Text("Account Settings coming soon...")
            .foregroundColor(.gray)
            .navigationTitle("Account Settings")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Noetica")
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color.purple)
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Noetica is a powerful note-taking and flashcard app designed for efficient learning and productivity.")
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .navigationTitle("About Noetica")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
