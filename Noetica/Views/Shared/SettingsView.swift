//
//  SettingsView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-16.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var statsService: StatsService

    @State private var showDeleteAccountAlert = false
    @State private var showLogoutAlert = false
    @State private var showAboutSheet = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    UserProfileSection(showEditProfile: $showEditProfile)
                    
                    AboutSupportSection(showAboutSheet: $showAboutSheet)
                    
                    AccountActionsSection(
                        showLogoutAlert: $showLogoutAlert,
                        showDeleteAccountAlert: $showDeleteAccountAlert
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(currentName: authService.userDisplayName)
        }
    }
}

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var nameText: String
    @State private var isSaving = false
    @State private var errorText: String?

    init(currentName: String) {
        _nameText = State(initialValue: currentName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Name")) {
                    TextField("Your name", text: $nameText)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        save()
                    }
                    .disabled(isSaving || nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        errorText = nil
        authService.updateDisplayName(to: trimmed) { result in
            isSaving = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorText = error.localizedDescription
            }
        }
    }
}

struct UserProfileSection: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var statsService: StatsService
    @Binding var showEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text(authService.userDisplayName.prefix(1).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 6) {
                        Text(authService.userDisplayName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(authService.userEmail)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Member since \(memberSinceDate)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showEditProfile = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("\(statsService.studyStats.currentStreak)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("Day Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        Text("\(String(format: "%.1f", statsService.studyStats.totalStudyHours))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("Hours Studied")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private var memberSinceDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if let creationDate = authService.user?.metadata.creationDate {
            return formatter.string(from: creationDate)
        }
        
        return formatter.string(from: Date())
    }
}

struct PreferencesSection: View {
    @Binding var isDarkMode: Bool
    @Binding var enableNotifications: Bool
    @Binding var autoBackup: Bool
    
    var body: some View {
        SettingsSection(title: "Preferences", icon: "gearshape.fill", iconColor: .blue) {
            SettingsRow(icon: "moon.fill", title: "Dark Mode", iconColor: .indigo) {
                Toggle("", isOn: $isDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            
            SettingsRow(icon: "bell.fill", title: "Notifications", iconColor: .orange) {
                Toggle("", isOn: $enableNotifications)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
            
            SettingsRow(icon: "icloud.fill", title: "Auto Backup", iconColor: .green) {
                Toggle("", isOn: $autoBackup)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
        }
    }
}

struct StudySettingsSection: View {
    @State private var defaultSessionLength = 25
    @State private var reviewReminders = true
    
    var body: some View {
        SettingsSection(title: "Study Settings", icon: "book.fill", iconColor: .purple) {
            NavigationLink(destination: Text("Pomodoro Settings")) {
                SettingsRow(icon: "timer", title: "Pomodoro Timer", iconColor: .red) {
                    HStack {
                        Text("\(defaultSessionLength) min")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            SettingsRow(icon: "alarm.fill", title: "Review Reminders", iconColor: .blue) {
                Toggle("", isOn: $reviewReminders)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            
            NavigationLink(destination: Text("Spaced Repetition Settings")) {
                SettingsRow(icon: "brain.head.profile", title: "Spaced Repetition", iconColor: .pink) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DataPrivacySection: View {
    var body: some View {
        SettingsSection(title: "Data & Privacy", icon: "lock.shield.fill", iconColor: .green) {
            NavigationLink(destination: Text("Export Data")) {
                SettingsRow(icon: "square.and.arrow.up", title: "Export Data", iconColor: .blue) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink(destination: Text("Privacy Policy")) {
                SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", iconColor: .orange) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
            }) {
                SettingsRow(icon: "trash.fill", title: "Clear Cache", iconColor: .red) {
                    Text("2.3 MB")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct AboutSupportSection: View {
    @Binding var showAboutSheet: Bool
    
    var body: some View {
        SettingsSection(title: "About & Support", icon: "questionmark.circle.fill", iconColor: .orange) {
            Button(action: { showAboutSheet = true }) {
                SettingsRow(icon: "info.circle.fill", title: "About Noetica", iconColor: .blue) {
                    HStack {
                        Text("v1.0.0")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: Text("Help & FAQ")) {
                SettingsRow(icon: "questionmark.circle", title: "Help & FAQ", iconColor: .green) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
            }) {
                SettingsRow(icon: "envelope.fill", title: "Contact Support", iconColor: .purple) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct AccountActionsSection: View {
    @Binding var showLogoutAlert: Bool
    @Binding var showDeleteAccountAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            Button(action: { showDeleteAccountAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Delete Account")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(icon: String, title: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Noetica")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Intelligent Learning Companion")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Noetica")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Noetica is designed to enhance your learning experience through intelligent spaced repetition, effective note-taking, and productivity tools. Built with modern learning science principles to help you learn better, faster, and retain more.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Features")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "rectangle.stack.fill", title: "Smart Flashcards", description: "Spaced repetition algorithm")
                            FeatureRow(icon: "doc.text.fill", title: "Intelligent Notes", description: "Organized note-taking system")
                            FeatureRow(icon: "timer", title: "Focus Timer", description: "Pomodoro technique integration")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking", description: "Detailed analytics and insights")
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthService())
            .environmentObject(StatsService())
            .environment(\.managedObjectContext, CoreDataService.shared.context)
    }
}
