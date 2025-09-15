//
//  PomodoroTimerView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI

struct PomodoroTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var statsService: StatsService
    
    @State private var selectedSession: PomodoroSessionType = .work
    @State private var timeRemaining: Int = PomodoroSessionType.work.duration
    @State private var timerRunning = false
    @State private var selectedSubject: String = "General"
    @State private var showSubjectPicker = false
    @State private var timer: Timer? = nil
    @State private var progress: Double = 1.0
    @State private var isAnimating = false
    @State private var completedSessions = 0
    @State private var currentPomodoroSession: PomodoroSession?
    @State private var showSessionCompleteAlert = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.subject, ascending: true)],
        animation: .default
    ) private var notes: FetchedResults<Note>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.name, ascending: true)],
        animation: .default
    ) private var decks: FetchedResults<Deck>
    
    var availableSubjects: [String] {
        let noteSubjects = Set(notes.compactMap { $0.subject }.filter { !$0.isEmpty })
        let deckNames = Set(decks.compactMap { $0.name }.filter { !$0.isEmpty })
        let allSubjects = Array(noteSubjects.union(deckNames)).sorted()
        return allSubjects.isEmpty ? ["General"] : ["General"] + allSubjects
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focus Timer")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Stay productive with the Pomodoro technique")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        SessionTypeSelector(selectedSession: $selectedSession, onSelectionChange: resetTimer)
                            .padding(.horizontal, 24)
                    }
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 8)
                                .frame(width: 280, height: 280)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(progress))
                                .stroke(
                                    selectedSession.color,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 280, height: 280)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                            
                            VStack(spacing: 12) {
                                Image(systemName: selectedSession.icon)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(selectedSession.color)
                                    .scaleEffect(timerRunning ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timerRunning)
                                
                                Text(timeString(timeRemaining))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .contentTransition(.numericText())
                                
                                Text(selectedSession.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedSession.color)
                                    .textCase(.uppercase)
                                    .tracking(1.2)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        StatsCard(completedSessions: completedSessions, currentSession: selectedSession)
                    }
                    
                    SubjectCard(
                        selectedSubject: $selectedSubject,
                        availableSubjects: availableSubjects,
                        showSubjectPicker: $showSubjectPicker
                    )
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            timerRunning ? pauseTimer() : startTimer()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text(timerRunning ? "Pause" : "Start")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedSession.color)
                            .cornerRadius(16)
                            .shadow(color: selectedSession.color.opacity(0.3), radius: 8, x: 0, y: 4)
                            .scaleEffect(timerRunning ? 0.98 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timerRunning)
                        }
                        .padding(.horizontal, 24)
                        
                        HStack(spacing: 20) {
                            ControlButton(
                                icon: "arrow.counterclockwise",
                                label: "Reset",
                                color: .orange,
                                action: resetTimer
                            )
                            
                            ControlButton(
                                icon: "stop.fill",
                                label: "Stop",
                                color: .red,
                                action: stopTimer
                            )
                            
                            ControlButton(
                                icon: "music.note",
                                label: "Music",
                                color: .purple,
                                action: {}
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showSubjectPicker) {
            SubjectPickerView(
                selectedSubject: $selectedSubject,
                availableSubjects: availableSubjects
            )
        }
        .alert("Session Complete!", isPresented: $showSessionCompleteAlert) {
            Button("Great!") {
                if selectedSession == .work {
                    selectedSession = completedSessions % 4 == 3 ? .longBreak : .shortBreak
                } else {
                    selectedSession = .work
                }
                resetTimer()
            }
        } message: {
            Text("You've completed a \(selectedSession.rawValue.lowercased()) session! Well done!")
        }
        .onAppear {
            resetTimer()
            loadTodaysCompletedSessions()
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .onDisappear(perform: stopTimer)
    }
    
    private func startTimer() {
        timerRunning = true
        
        currentPomodoroSession = CoreDataService.shared.createPomodoroSession(
            subjectOrDeck: selectedSubject,
            sessionType: selectedSession.rawValue,
            duration: Int16(selectedSession.duration / 60)
        )
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                progress = Double(timeRemaining) / Double(selectedSession.duration)
            } else {
                completeSession()
            }
        }
    }
    
    private func pauseTimer() {
        timerRunning = false
        timer?.invalidate()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timerRunning = false
        
        currentPomodoroSession = nil
    }
    
    private func completeSession() {
        timer?.invalidate()
        timerRunning = false
        
        if let session = currentPomodoroSession {
            CoreDataService.shared.completePomodoroSession(session)
            completedSessions += 1
            statsService.updateStats()
        }
        
        showSessionCompleteAlert = true
        currentPomodoroSession = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = selectedSession.duration
        progress = 1.0
    }
    
    private func loadTodaysCompletedSessions() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        let todaySessions = CoreDataService.shared.fetchCompletedSessions(from: today, to: tomorrow)
        completedSessions = todaySessions.count
    }
    
    private func timeString(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

struct SessionTypeSelector: View {
    @Binding var selectedSession: PomodoroSessionType
    let onSelectionChange: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(PomodoroSessionType.allCases) { session in
                Button(action: {
                    selectedSession = session
                    onSelectionChange()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: session.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(selectedSession == session ? .white : session.color)
                        
                        Text(session.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedSession == session ? .white : session.color)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedSession == session ? session.color : Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(session.color, lineWidth: selectedSession == session ? 0 : 2)
                            )
                    )
                    .shadow(color: selectedSession == session ? session.color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    .scaleEffect(selectedSession == session ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedSession)
                }
            }
        }
    }
}

struct StatsCard: View {
    let completedSessions: Int
    let currentSession: PomodoroSessionType
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(completedSessions)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(currentSession.color)
                
                Text("Today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text("\(currentSession.duration / 60)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(currentSession.color)
                
                Text("Minutes")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("Focus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }
}

struct SubjectCard: View {
    @Binding var selectedSubject: String
    let availableSubjects: [String]
    @Binding var showSubjectPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Focus Subject")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Button(action: { showSubjectPicker.toggle() }) {
                HStack(spacing: 12) {
                    Text(selectedSubject)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SubjectPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSubject: String
    let availableSubjects: [String]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(availableSubjects, id: \.self) { subject in
                        Button(action: {
                            selectedSubject = subject
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subject)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if subject != "General" {
                                        Text("From your notes/decks")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if subject == selectedSubject {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
            .environment(\.managedObjectContext, CoreDataService.shared.context)
            .environmentObject(StatsService())
    }
}
