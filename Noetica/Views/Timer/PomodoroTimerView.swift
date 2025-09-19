//
//  PomodoroTimerView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI
import AVFoundation
import UserNotifications

struct PomodoroTimerView: View {
    @State private var timeRemaining = 1500
    @State private var isActive = false
    @State private var showingBreak = false
    @State private var sessionType: PomodoroSessionType = .work
    @State private var currentSession = 0
    @State private var totalSessions = 4
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingSessionComplete = false
    
    @State private var linkedCalendarEvent: CalendarEvent?
    @State private var currentPomodoroSession: PomodoroSession?
    @State private var selectedSubject: String = ""
    @State private var selectedDeck: Deck?
    @State private var availableSubjects: [String] = []
    @State private var availableDecks: [Deck] = []
    @State private var showingSubjectSelection = false
    
    @State private var isQuickSession = false
    @State private var quickSessionType: EventType = .studySession
    
    @EnvironmentObject private var authService: AuthService
    @StateObject private var coreDataService = CoreDataService.shared
    
    private let colors = [
        PomodoroSessionType.work: Color.red,
        PomodoroSessionType.shortBreak: Color.green,
        PomodoroSessionType.longBreak: Color.blue
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    
                    headerSection
                    
                    timerDisplaySection(geometry: geometry)
                    
                    if !isActive && currentPomodoroSession == nil && !isQuickSession {
                        sessionSetupSection
                    }
                    
                    controlButtonsSection
                    
                    sessionProgressSection
                    
                    if !isActive && currentPomodoroSession == nil {
                        quickActionsSection
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAvailableData()
            setupDefaultSession()
        }
        .onDisappear {
            if isActive {
                pauseTimer()
            }
        }
        .alert("Session Complete!", isPresented: $showingSessionComplete) {
            Button("Continue") {
                completeCurrentSession()
            }
            Button("Take Break") {
                startBreakSession()
            }
        } message: {
            Text("Great work! You've completed your \(sessionType.rawValue.lowercased()) session.")
        }
    }
    
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(getSessionTitle())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            if let subject = getSessionSubtitle() {
                Text(subject)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(sessionType.color.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(sessionType.color.opacity(0.3), lineWidth: 1)
                    )
            }
            
            if linkedCalendarEvent != nil {
                Label("Linked to calendar event", systemImage: "link.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func timerDisplaySection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(sessionType.color.opacity(0.1), lineWidth: 12)
                    .frame(width: min(geometry.size.width - 80, 280), height: min(geometry.size.width - 80, 280))
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            colors: [sessionType.color.opacity(0.8), sessionType.color],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: min(geometry.size.width - 80, 280), height: min(geometry.size.width - 80, 280))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    Text(sessionType.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(sessionType.color)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }
        }
    }
    
    private var sessionSetupSection: some View {
        VStack(spacing: 20) {
            Text("Setup Your Session")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Text("Session Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    SessionTypeButton(
                        title: "Study Session",
                        icon: "book.fill",
                        isSelected: quickSessionType == .studySession,
                        color: .blue
                    ) {
                        quickSessionType = .studySession
                        selectedDeck = nil
                    }
                    
                    SessionTypeButton(
                        title: "Flashcards",
                        icon: "rectangle.stack.fill",
                        isSelected: quickSessionType == .flashcards,
                        color: .green
                    ) {
                        quickSessionType = .flashcards
                        selectedSubject = ""
                    }
                }
            }
            
            if quickSessionType == .studySession {
                subjectSelectionSection
            } else {
                deckSelectionSection
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var subjectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Subject")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            if availableSubjects.isEmpty {
                TextField("Enter subject name", text: $selectedSubject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                VStack(spacing: 8) {
                    Picker("Subject", selection: $selectedSubject) {
                        Text("Select Subject").tag("")
                        ForEach(availableSubjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Or enter new subject", text: $selectedSubject)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    private var deckSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flashcard Deck")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            if availableDecks.isEmpty {
                Text("No decks available. Create a deck first.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            } else {
                Picker("Deck", selection: $selectedDeck) {
                    Text("Select Deck").tag(nil as Deck?)
                    ForEach(availableDecks, id: \.id) { deck in
                        Text(deck.name ?? "Unnamed Deck").tag(deck as Deck?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    private var controlButtonsSection: some View {
        HStack(spacing: 20) {
            if isActive {
                Button(action: pauseTimer) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.orange)
                        )
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: stopTimer) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.red)
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
            } else {
                Button(action: startTimer) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text(currentPomodoroSession != nil ? "Resume" : "Start Session")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [sessionType.color.opacity(0.8), sessionType.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: sessionType.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(!canStartSession)
            }
        }
    }
    
    private var sessionProgressSection: some View {
        VStack(spacing: 16) {
            Text("Session \(currentSession + 1) of \(totalSessions)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(0..<totalSessions, id: \.self) { index in
                    Circle()
                        .fill(index <= currentSession ? sessionType.color : Color(.systemGray4))
                        .frame(width: 12, height: 12)
                        .scaleEffect(index == currentSession ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentSession)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "25 min",
                    subtitle: "Focus",
                    color: .red,
                    action: { setQuickSession(minutes: 25) }
                )
                
                QuickActionButton(
                    title: "15 min",
                    subtitle: "Quick Study",
                    color: .blue,
                    action: { setQuickSession(minutes: 15) }
                )
                
                QuickActionButton(
                    title: "45 min",
                    subtitle: "Deep Work",
                    color: .purple,
                    action: { setQuickSession(minutes: 45) }
                )
            }
        }
    }
    
    
    private var backgroundColor: Color {
        Color(.systemGroupedBackground)
    }
    
    private var progress: Double {
        let totalTime = Double(sessionType.duration * 60)
        return (totalTime - Double(timeRemaining)) / totalTime
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var canStartSession: Bool {
        if quickSessionType == .studySession {
            return !selectedSubject.isEmpty
        } else {
            return selectedDeck != nil
        }
    }
    
    
    private func getSessionTitle() -> String {
        if let event = linkedCalendarEvent {
            return event.title
        } else if quickSessionType == .studySession {
            return selectedSubject.isEmpty ? "Study Session" : "Study: \(selectedSubject)"
        } else {
            return selectedDeck?.name.map { "Flashcards: \($0)" } ?? "Flashcard Review"
        }
    }
    
    private func getSessionSubtitle() -> String? {
        if let event = linkedCalendarEvent {
            if let subject = event.subject {
                return "Subject: \(subject)"
            } else if let deckName = event.deckName {
                return "Deck: \(deckName)"
            }
        }
        return nil
    }
    
    private func loadAvailableData() {
        availableSubjects = coreDataService.getUniqueSubjects()
        availableDecks = coreDataService.fetchDecks()
    }
    
    private func setupDefaultSession() {
        timeRemaining = sessionType.duration * 60
        
        if !availableSubjects.isEmpty && selectedSubject.isEmpty {
            selectedSubject = availableSubjects[0]
        }
        if !availableDecks.isEmpty && selectedDeck == nil {
            selectedDeck = availableDecks[0]
        }
    }
    
    private func setQuickSession(minutes: Int) {
        sessionType = .work
        timeRemaining = minutes * 60
    }
    
    
    private func startTimer() {
        if currentPomodoroSession == nil {
            createLinkedCalendarEventAndSession()
        }
        
        isActive = true
        startTimerLoop()
    }
    
    private func createLinkedCalendarEventAndSession() {
        let now = Date()
        let duration = TimeInterval(timeRemaining)
        let endTime = now.addingTimeInterval(duration)
        
        let calendarEvent = coreDataService.createCalendarEvent(
            title: getSessionTitle(),
            description: "Pomodoro session created from timer",
            startTime: now,
            endTime: endTime,
            type: quickSessionType,
            subject: quickSessionType == .studySession ? selectedSubject : nil,
            deckName: quickSessionType == .flashcards ? selectedDeck?.name : nil,
            autoCreateSession: false
        )
        
        let pomodoroSession = coreDataService.createPomodoroSession(
            subjectOrDeck: quickSessionType == .studySession ? selectedSubject : (selectedDeck?.name ?? "Unknown"),
            sessionType: quickSessionType.rawValue,
            duration: Int16(timeRemaining / 60),
            linkedEventId: calendarEvent.id,
            startTime: now
        )
        
        linkedCalendarEvent = calendarEvent
        currentPomodoroSession = pomodoroSession
        
        print("Created linked calendar event and Pomodoro session")
    }
    
    private func startTimerLoop() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.isActive && self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else if self.timeRemaining <= 0 {
                timer.invalidate()
                self.sessionComplete()
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func pauseTimer() {
        isActive = false
    }
    
    private func stopTimer() {
        isActive = false
        timeRemaining = sessionType.duration * 60
        
        if let session = currentPomodoroSession {
            currentPomodoroSession = nil
            linkedCalendarEvent = nil
        }
    }
    
    private func sessionComplete() {
        isActive = false
        playCompletionSound()
        showingSessionComplete = true
        
        if let session = currentPomodoroSession {
            coreDataService.markPomodoroSessionCompleted(sessionId: session.id!)
        }
        
        if let event = linkedCalendarEvent {
            coreDataService.markEventCompleted(event)
        }
   
    }
    
    private func completeCurrentSession() {
        currentSession += 1
        currentPomodoroSession = nil
        linkedCalendarEvent = nil
        
        if currentSession < totalSessions {
            sessionType = .work
            timeRemaining = sessionType.duration * 60
        } else {
            currentSession = 0
            sessionType = .work
            timeRemaining = sessionType.duration * 60
        }
    }
    
    private func startBreakSession() {
        currentPomodoroSession = nil
        linkedCalendarEvent = nil
        
        sessionType = (currentSession % 4 == 0) ? .longBreak : .shortBreak
        timeRemaining = sessionType.duration * 60
    }
    
    private func playCompletionSound() {
        guard let url = Bundle.main.url(forResource: "completion", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play completion sound: \(error)")
        }
    }
    
    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "Great work! You've completed your \(sessionType.rawValue.lowercased()) session."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "session_complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}


struct SessionTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    PomodoroTimerView()
        .environmentObject(AuthService())
}
