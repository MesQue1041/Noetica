//
//  PomodoroTimerService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-19.
//

import Foundation
import SwiftUI
import AVFoundation
import UserNotifications

class PomodoroTimerService: ObservableObject {
    static let shared = PomodoroTimerService()
    
    @Published var isRunning = false
    @Published var timeRemaining: Int = 0
    @Published var currentSession: PomodoroSession?
    @Published var currentEvent: CalendarEvent?
    
    private var timer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    
    func startSession(event: CalendarEvent) {
        stopSession()
        
        currentEvent = event
        
        if let sessionId = event.linkedSessionId,
           let session = fetchPomodoroSession(id: sessionId) {
            currentSession = session
            timeRemaining = Int(session.duration) * 60
        } else {
            let duration = Int(event.endTime.timeIntervalSince(event.startTime)) / 60
            let session = CoreDataService.shared.createPomodoroSession(
                subjectOrDeck: event.subject ?? event.deckName ?? event.title,
                sessionType: event.type.rawValue,
                duration: Int16(duration),
                linkedEventId: event.id,
                startTime: Date()
            )
            currentSession = session
            timeRemaining = Int(session.duration) * 60
        }
        
        isRunning = true
        startBackgroundTask()
        startTimer()
        
        print("Started session: \(event.title)")
    }
    
    func pauseSession() {
        isRunning = false
        timer?.invalidate()
        endBackgroundTask()
    }
    
    func resumeSession() {
        guard currentSession != nil else { return }
        isRunning = true
        startBackgroundTask()
        startTimer()
    }
    
    func stopSession() {
        isRunning = false
        timer?.invalidate()
        endBackgroundTask()
        
        currentSession = nil
        currentEvent = nil
        timeRemaining = 0
        
        print("Session stopped")
    }
    
    func completeSession() {
        guard let session = currentSession,
              let event = currentEvent else { return }
        
        CoreDataService.shared.markPomodoroSessionCompleted(sessionId: session.id!)
        CoreDataService.shared.markEventCompleted(event)
        
        sendCompletionNotification()
        
        stopSession()
        
        print("Session completed successfully")
    }
    
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.completeSession()
            }
        }
    }
    
    private func startBackgroundTask() {
        endBackgroundTask()
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "PomodoroTimer") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func fetchPomodoroSession(id: UUID) -> PomodoroSession? {
        let request = PomodoroSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let sessions = try CoreDataService.shared.context.fetch(request)
            return sessions.first
        } catch {
            print("Error fetching session: \(error)")
            return nil
        }
    }
    
    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "Great work! You've completed your study session."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "session_complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard let event = currentEvent else { return 0.0 }
        
        let totalDuration = event.endTime.timeIntervalSince(event.startTime)
        guard totalDuration > 0, timeRemaining >= 0 else { return 0.0 }
        
        let currentProgress = (totalDuration - Double(timeRemaining)) / totalDuration
        return max(0.0, min(1.0, currentProgress))
    }

}
