//
//  HomeDashboard.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI

struct HomeDashboardView: View {
    @State private var currentTime = Date()
    @State private var showingPomodoroTimer = false
    @State private var showingARFlashcards = false
    
    @State private var upcomingSessions = [
        StudySession(title: "Math Review", time: "2:30 PM", type: .pomodoro, subject: "Mathematics"),
        StudySession(title: "French Vocab", time: "4:00 PM", type: .flashcard, subject: "French"),
        StudySession(title: "Physics Notes", time: "6:15 PM", type: .pomodoro, subject: "Physics")
    ]
    
    @State private var studyRecommendations = [
        StudyRecommendation(title: "Review Biology Flashcards", reason: "You found these difficult yesterday", priority: .high, type: .flashcard),
        StudyRecommendation(title: "Continue Chemistry Notes", reason: "Haven't studied this week", priority: .medium, type: .notes),
        StudyRecommendation(title: "Practice Math Problems", reason: "Due for review", priority: .low, type: .pomodoro)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HeaderSection()
                    
                    UpcomingSessionsSection(sessions: upcomingSessions, showingPomodoroTimer: $showingPomodoroTimer)
                    
                    QuickAccessSection(showingARFlashcards: $showingARFlashcards)
                    
                    StudyRecommendationsSection(recommendations: studyRecommendations)
                    
                    StudyStreakCard()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPomodoroTimer) {
            PomodoroTimerView()
        }
        .sheet(isPresented: $showingARFlashcards) {
            FlashcardReviewView(flashcards: [])
        }
        .onAppear {
            startTimeUpdater()
        }
    }
    
    private func startTimeUpdater() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

struct HeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDayGreeting()),")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Abdul!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text("A")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
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
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
                    action: {}
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
                    action: {}
                )
                
                QuickActionCard(
                    title: "Browse Decks",
                    subtitle: "Review cards",
                    icon: "rectangle.stack",
                    color: .green,
                    action: {}
                )
            }
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
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
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("7 Day Streak!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Keep up the great work")
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
            .preferredColorScheme(.light)
    }
}

