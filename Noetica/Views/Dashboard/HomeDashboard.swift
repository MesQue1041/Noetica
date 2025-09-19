//
//  HomeDashboard.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI
import CoreData
import UserNotifications

struct HomeDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var statsService: StatsService
    @StateObject private var notificationService = NotificationService.shared
    @State private var currentTime = Date()
    @State private var showingPomodoroTimer = false
    @State private var showingARFlashcards = false
    @State private var showingSettings = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateModified, ascending: false)],
        animation: .default
    ) private var allNotes: FetchedResults<Note>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.name, ascending: true)],
        animation: .default
    ) private var allDecks: FetchedResults<Deck>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: false)],
        animation: .default
    ) private var allFlashcards: FetchedResults<Flashcard>
    
    @State private var todaysSessions: [StudySession] = []
    @State private var recommendations: [StudyRecommendation] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HeaderSection(showingSettings: $showingSettings)
                
                StatsOverviewSection(
                    totalNotes: allNotes.count,
                    totalFlashcards: allFlashcards.count,
                    totalStudyHours: statsService.studyStats.totalStudyHours
                )
                
                UpcomingSessionsSection(sessions: todaysSessions, showingPomodoroTimer: $showingPomodoroTimer)
                
                QuickAccessSection(showingARFlashcards: $showingARFlashcards)
                
                StudyRecommendationsSection(recommendations: recommendations)
                
                StudyStreakCard(streak: statsService.studyStats.currentStreak)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showingPomodoroTimer) {
            PomodoroTimerView()
        }
        .sheet(isPresented: $showingARFlashcards) {
            ARFlashcardReviewView(flashcards: Array(allFlashcards), isPresented: $showingARFlashcards)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(authService)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(statsService)
        }
        .onAppear {
            startTimeUpdater()
            statsService.updateStats()
            generateRecommendations()
            generateTodaysSessions()
            scheduleSmartNotifications()
        }
        .onChange(of: allNotes.count) { _ in
            generateRecommendations()
            generateTodaysSessions()
        }
        .onChange(of: allDecks.count) { _ in
            generateRecommendations()
            generateTodaysSessions()
        }
        .onChange(of: allFlashcards.count) { _ in
            generateRecommendations()
        }
    }

    private func startTimeUpdater() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func scheduleSmartNotifications() {
        notificationService.scheduleDailyFlashcardReminder()
        
        let dueFlashcards = SpacedRepetitionService.shared.getDueFlashcards()
        if !dueFlashcards.isEmpty {
            notificationService.scheduleSpacedRepetitionReminder(for: dueFlashcards)
        }
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let completedSessionsToday = CoreDataService.shared.fetchCompletedSessions(
            from: startOfDay,
            to: today
        )
        
        if completedSessionsToday.isEmpty {
            notificationService.scheduleStreakRiskReminder()
        }
    }
    
    private func generateTodaysSessions() {
        var sessions: [StudySession] = []
        
        let recentSubjects = Array(Set(allNotes.prefix(5).compactMap { $0.subject }))
        for (index, subject) in recentSubjects.enumerated() {
            let hour = 9 + (index * 2)
            sessions.append(StudySession(
                id: UUID(),
                title: "\(subject) Review",
                time: "\(hour):00 AM",
                type: .pomodoro,
                subject: subject
            ))
        }
        
        for (index, deck) in allDecks.prefix(2).enumerated() {
            let hour = 14 + index
            sessions.append(StudySession(
                id: UUID(),
                title: deck.name ?? "Flashcard Review",
                time: "\(hour):00 PM",
                type: .flashcard,
                subject: deck.subject ?? "General"
            ))
        }
        
        todaysSessions = sessions
    }
      
    private func generateRecommendations() {
        var recs: [StudyRecommendation] = []
        
        let lowMasteryDecks = allDecks.filter { $0.mastery < 0.5 }
        for deck in lowMasteryDecks.prefix(2) {
            recs.append(StudyRecommendation(
                id: UUID(),
                title: "Review \(deck.name ?? "Flashcards")",
                reason: "Low mastery level (\(Int(deck.mastery * 100))%)",
                priority: deck.mastery < 0.3 ? .high : .medium,
                type: .flashcard,
                subject: nil,
                deckName: deck.name
            ))
        }
        
        let oldNotes = allNotes.filter { note in
            guard let modified = note.dateModified else { return false }
            return Date().timeIntervalSince(modified) > 7 * 24 * 60 * 60
        }
        
        let oldSubjects = Array(Set(oldNotes.prefix(3).compactMap { $0.subject }))
        for subject in oldSubjects {
            recs.append(StudyRecommendation(
                id: UUID(),
                title: "Review \(subject) Notes",
                reason: "Haven't studied in over a week",
                priority: .medium,
                type: .notes,
                subject: subject,
                deckName: nil
            ))
        }
        
        if recs.isEmpty {
            recs.append(StudyRecommendation(
                id: UUID(),
                title: "Start Your First Study Session",
                reason: "Build a consistent learning habit",
                priority: .high,
                type: .pomodoro,
                subject: nil,
                deckName: nil
            ))
        }
        
        recommendations = recs
    }
}

struct StatsOverviewSection: View {
    let totalNotes: Int
    let totalFlashcards: Int
    let totalStudyHours: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                DashboardStatCard(
                    title: "Notes",
                    value: "\(totalNotes)",
                    icon: "doc.text.fill",
                    color: .blue
                )
                
                DashboardStatCard(
                    title: "Cards",
                    value: "\(totalFlashcards)",
                    icon: "rectangle.stack.fill",
                    color: .purple
                )
                
                DashboardStatCard(
                    title: "Hours",
                    value: String(format: "%.1f", totalStudyHours),
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(title)")
        .accessibilityValue("Current count: \(value)")
        .accessibilityAddTraits([.updatesFrequently])
    }
}

struct HeaderSection: View {
    @Binding var showingSettings: Bool
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDayGreeting()),")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("\(authService.userDisplayName)!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(authService.userDisplayName.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .accessibilityLabel("Profile settings")
                .accessibilityHint("Tap to open settings and profile")
            }
            
            Text("Ready to boost your learning?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func timeOfDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
}
struct UpcomingSessionsSection: View {
    let sessions: [StudySession]
    @Binding var showingPomodoroTimer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Schedule")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if sessions.isEmpty {
                EmptySessionsCard()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sessions.prefix(3)) { session in
                        SessionCard(session: session, showingPomodoroTimer: $showingPomodoroTimer)
                    }
                }
            }
        }
    }
}

struct SessionCard: View {
    let session: StudySession
    @Binding var showingPomodoroTimer: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(session.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: session.type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(session.type.color)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack {
                    Text(session.time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(session.subject)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                if session.type == .pomodoro {
                    showingPomodoroTimer = true
                }
            }) {
                Text("Start")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(session.type.color)
                    .cornerRadius(16)
            }
            .accessibilityLabel("Start \(session.title)")
            .accessibilityHint("Begin this study session")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.title) at \(session.time)")
        .accessibilityValue("Subject: \(session.subject)")
        .accessibilityAction(named: "Start session") {
            if session.type == .pomodoro {
                showingPomodoroTimer = true
            }
        }
    }
}


struct EmptySessionsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text("No sessions scheduled")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Tap the calendar tab to schedule your study sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct QuickAccessSection: View {
    @Binding var showingARFlashcards: Bool
    @State private var showingPomodoroTimer = false
    @State private var showingCreateNote = false
    @State private var showingDecksView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Start Pomodoro",
                    subtitle: "Focus session",
                    icon: "timer",
                    color: .orange,
                    action: { showingPomodoroTimer = true }
                )
                
                QuickActionCard(
                    title: "AR Flashcards",
                    subtitle: "Immersive review",
                    icon: "arkit",
                    color: .purple,
                    action: { showingARFlashcards = true }
                )
                
                QuickActionCard(
                    title: "Quick Note",
                    subtitle: "Capture ideas",
                    icon: "doc.text",
                    color: .blue,
                    action: { showingCreateNote = true }
                )
                
                QuickActionCard(
                    title: "Browse Decks",
                    subtitle: "Review cards",
                    icon: "rectangle.stack",
                    color: .green,
                    action: { showingDecksView = true }
                )
            }
        }
        .sheet(isPresented: $showingPomodoroTimer) {
            PomodoroTimerView()
        }
        .sheet(isPresented: $showingCreateNote) {
            CreatePageView()
        }
        .sheet(isPresented: $showingDecksView) {
            DecksView()
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(color)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)")
        .accessibilityHint("\(subtitle)")
        .frame(minWidth: 44, minHeight: 44)
    }
}


struct StudyRecommendationsSection: View {
    let recommendations: [StudyRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended for You")
                .font(.title3)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(recommendations.prefix(3)) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: StudyRecommendation
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(recommendation.priority.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(recommendation.reason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: recommendation.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct StudyStreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak) Day Streak!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(streak > 0 ? "Keep up the great work" : "Start your learning journey")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.orange, .red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

struct HomeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HomeDashboardView()
            .environment(\.managedObjectContext, CoreDataService.shared.context)
            .environmentObject(StatsService())
            .preferredColorScheme(.light)
            .environmentObject(AuthService())
    }
}
