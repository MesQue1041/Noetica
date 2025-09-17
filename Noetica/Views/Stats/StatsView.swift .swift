//
//  StatsView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var statsService: StatsService
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var showingDetailedStats = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Statistics")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Track your learning progress")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingDetailedStats = true
                        }) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTimeframe = timeframe
                                }
                            }) {
                                Text(timeframe.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedTimeframe == timeframe ? .white : .blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedTimeframe == timeframe ? Color.blue : Color.blue.opacity(0.1))
                                    )
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                MainStatsSection(stats: statsService.studyStats)
                    .padding(.horizontal, 20)
                
                StudyStreakSection(streak: statsService.studyStats.currentStreak)
                    .padding(.horizontal, 20)
                
                SubjectBreakdownSection(subjects: statsService.getSubjectStats())
                    .padding(.horizontal, 20)
                
                DeckPerformanceSection(decks: statsService.getDeckStats())
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDetailedStats) {
            DetailedStatsView()
        }
        .onAppear {
            statsService.updateStats()
        }
    }
}

struct MainStatsSection: View {
    let stats: StudyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title3)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                StatCard(
                    title: "Notes Created",
                    value: "\(stats.totalNotes)",
                    icon: "doc.text.fill",
                    color: .blue,
                    trend: stats.totalNotes > 0 ? .up : .neutral
                )
                
                StatCard(
                    title: "Flashcards",
                    value: "\(stats.totalFlashcards)",
                    icon: "rectangle.stack.fill",
                    color: .purple,
                    trend: stats.totalFlashcards > 0 ? .up : .neutral
                )
                
                StatCard(
                    title: "Study Hours",
                    value: String(format: "%.1fh", stats.totalStudyHours),
                    icon: "clock.fill",
                    color: .green,
                    trend: stats.totalStudyHours > 0 ? .up : .neutral
                )
                
                StatCard(
                    title: "Avg Mastery",
                    value: "\(Int(stats.averageMastery * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange,
                    trend: stats.averageMastery > 0.5 ? .up : stats.averageMastery > 0.2 ? .neutral : .down
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(trend.color)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(trend.color.opacity(0.1))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

struct StudyStreakSection: View {
    let streak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Streak")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("\(streak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Day Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(getStreakMessage(for: streak))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(getStreakTip(for: streak))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private func getStreakMessage(for streak: Int) -> String {
        switch streak {
        case 0: return "Start Your Journey"
        case 1...3: return "Getting Started!"
        case 4...7: return "Building Momentum"
        case 8...14: return "Great Progress!"
        case 15...30: return "Excellent Habit!"
        default: return "Streak Master!"
        }
    }
    
    private func getStreakTip(for streak: Int) -> String {
        switch streak {
        case 0: return "Complete your first study session to start your streak"
        case 1...3: return "Keep going! Consistency is key to building a habit"
        case 4...7: return "You're building a solid routine. Stay focused!"
        default: return "Amazing dedication! You're a learning champion"
        }
    }
}

struct SubjectBreakdownSection: View {
    let subjects: [(subject: String, noteCount: Int, color: Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Subject Breakdown")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !subjects.isEmpty {
                    Text("\(subjects.count) subjects")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if subjects.isEmpty {
                EmptySubjectView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(subjects.indices, id: \.self) { index in
                        let subject = subjects[index]
                        SubjectRow(
                            name: subject.subject,
                            noteCount: subject.noteCount,
                            color: subject.color,
                            percentage: getPercentage(for: subject.noteCount)
                        )
                    }
                }
            }
        }
    }
    
    private func getPercentage(for count: Int) -> Double {
        let total = subjects.reduce(0) { $0 + $1.noteCount }
        return total > 0 ? Double(count) / Double(total) : 0
    }
}

struct SubjectRow: View {
    let name: String
    let noteCount: Int
    let color: Color
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(noteCount) notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(percentage), height: 6)
                            .animation(.easeInOut(duration: 0.8), value: percentage)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct DeckPerformanceSection: View {
    let decks: [(deck: Deck, flashcardCount: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Deck Performance")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !decks.isEmpty {
                    Text("\(decks.count) decks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if decks.isEmpty {
                EmptyDeckView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(decks.indices, id: \.self) { index in
                        let deckData = decks[index]
                        DeckPerformanceRow(
                            name: deckData.deck.name ?? "Untitled Deck",
                            flashcardCount: deckData.flashcardCount,
                            mastery: deckData.deck.mastery,
                            subject: deckData.deck.subject ?? "General"
                        )
                    }
                }
            }
        }
    }
}

struct DeckPerformanceRow: View {
    let name: String
    let flashcardCount: Int
    let mastery: Double
    let subject: String
    
    var masteryColor: Color {
        switch mastery {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Circle()
                    .stroke(masteryColor.opacity(0.3), lineWidth: 4)
                    .background(
                        Circle()
                            .trim(from: 0, to: CGFloat(mastery))
                            .stroke(masteryColor, lineWidth: 4)
                            .rotationEffect(.degrees(-90))
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("\(Int(mastery * 100))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(masteryColor)
                    )
                
                Text("\(Int(mastery * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(subject)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                    
                    Text("\(flashcardCount) cards")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct EmptySubjectView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Subjects Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Create notes to see subject breakdown")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }
}

struct EmptyDeckView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Decks Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Create flashcard decks to track performance")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }
}

struct DetailedStatsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Detailed Statistics")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Advanced analytics and detailed reports will be available here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Detailed Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environment(\.managedObjectContext, CoreDataService.shared.context)
            .environmentObject(StatsService())
            .environmentObject(AuthService())
    }
}
