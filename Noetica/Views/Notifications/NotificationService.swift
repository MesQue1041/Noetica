//
//  NotificationService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
                self.checkAuthorizationStatus()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    
    func scheduleSessionReminder(for event: CalendarEvent, minutesBefore: Int = 10) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let reminderTime = event.startTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        
        guard reminderTime > Date() else {
            print("Reminder time is in the past")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Study Session Starting Soon"
        
        if event.type == .studySession {
            content.body = "Your study session '\(event.subject ?? "General")' starts in \(minutesBefore) minutes"
            content.categoryIdentifier = "STUDY_REMINDER"
        } else {
            content.body = "Your flashcard review '\(event.deckName ?? "General")' starts in \(minutesBefore) minutes"
            content.categoryIdentifier = "FLASHCARD_REMINDER"
        }
        
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        content.userInfo = [
            "eventId": event.id.uuidString,
            "eventType": event.type.rawValue,
            "subject": event.subject ?? "",
            "deckName": event.deckName ?? ""
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "session_reminder_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling session reminder: \(error.localizedDescription)")
            } else {
                print("Scheduled session reminder for \(event.title)")
            }
        }
    }
    
    func scheduleSessionStartNotification(for event: CalendarEvent) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Session Starting Now!"
        
        if event.type == .studySession {
            content.body = "Your '\(event.subject ?? "Study")' session is ready to begin"
        } else {
            content.body = "Your '\(event.deckName ?? "Flashcard")' review is ready to begin"
        }
        
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = "SESSION_START"
        
        let startAction = UNNotificationAction(
            identifier: "START_SESSION",
            title: "Start Now",
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_SESSION",
            title: "5 min later",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "SESSION_START",
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        content.userInfo = [
            "eventId": event.id.uuidString,
            "eventType": event.type.rawValue
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: event.startTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "session_start_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling start notification: \(error)")
            } else {
                print("Scheduled session start notification for \(event.startTime)")
            }
        }
    }

    
    func scheduleDailyFlashcardReminder() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Review!"
        content.body = "You have flashcards due for review. Keep your learning streak going!"
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = "DAILY_REVIEW"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_flashcard_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error.localizedDescription)")
            } else {
                print("Scheduled daily flashcard reminder")
            }
        }
    }
    
    func scheduleSpacedRepetitionReminder(for flashcards: [Flashcard]) {
        guard isAuthorized && !flashcards.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Flashcards Due!"
        
        if flashcards.count == 1 {
            content.body = "You have 1 flashcard ready for review"
        } else {
            content.body = "You have \(flashcards.count) flashcards ready for review"
        }
        
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: flashcards.count)
        content.categoryIdentifier = "SPACED_REPETITION"
        
        let flashcardIds = flashcards.compactMap { $0.id?.uuidString }
        content.userInfo = [
            "flashcardIds": flashcardIds,
            "count": flashcards.count
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "spaced_repetition_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling spaced repetition reminder: \(error.localizedDescription)")
            } else {
                print("Scheduled spaced repetition reminder for \(flashcards.count) cards")
            }
        }
    }
    
    
    func scheduleStreakRiskReminder() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        content.body = "You haven't studied today. A quick 15-minute session can keep your streak alive!"
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = "STREAK_RISK"
        
        let calendar = Calendar.current
        let today = Date()
        let reminderTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today
        
        guard reminderTime > Date() else { return }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "streak_risk_\(calendar.dateInterval(of: .day, for: today)?.start.timeIntervalSince1970 ?? 0)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling streak reminder: \(error.localizedDescription)")
            } else {
                print("Scheduled streak risk reminder")
            }
        }
    }
    
    
    func sendSessionCompletionNotification(sessionType: String, subject: String?) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        
        if let subject = subject {
            content.body = "Great work! You've completed your \(sessionType.lowercased()) session for \(subject)"
        } else {
            content.body = "Great work! You've completed your \(sessionType.lowercased()) session"
        }
        
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SESSION_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "session_complete_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending completion notification: \(error.localizedDescription)")
            } else {
                print("Sent session completion notification")
            }
        }
    }
    
    
    func cancelNotification(withId identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelEventNotifications(for event: CalendarEvent) {
        let identifier = "session_reminder_\(event.id.uuidString)"
        cancelNotification(withId: identifier)
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending notifications: \(requests.count)")
            for request in requests {
                print("  - \(request.identifier): \(request.content.title)")
            }
        }
    }
    
    
    func scheduleSmartReminders() {
        scheduleDailyFlashcardReminder()
        
        let dueFlashcards = SpacedRepetitionService.shared.getDueFlashcards()
        if !dueFlashcards.isEmpty {
            scheduleSpacedRepetitionReminder(for: dueFlashcards)
        }
        
        let today = Date()
        let completedSessionsToday = CoreDataService.shared.fetchCompletedSessions(
            from: Calendar.current.startOfDay(for: today),
            to: today
        )
        
        if completedSessionsToday.isEmpty {
            scheduleStreakRiskReminder()
        }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("Notification received in foreground: \(notification.request.content.title)")
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        print("User tapped notification: \(response.notification.request.content.title)")
        
        switch response.notification.request.content.categoryIdentifier {
        case "STUDY_REMINDER", "FLASHCARD_REMINDER":
            handleSessionReminderTap(userInfo: userInfo)
            
        case "SPACED_REPETITION", "DAILY_REVIEW":
            handleFlashcardReminderTap(userInfo: userInfo)
            
        case "STREAK_RISK":
            handleStreakReminderTap()
            
        case "SESSION_COMPLETE":
            handleSessionCompleteTap()
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleSessionReminderTap(userInfo: [AnyHashable: Any]) {
        print("Handling session reminder tap")
        
        NotificationCenter.default.post(name: .navigateToTimer, object: userInfo)
    }
    
    private func handleFlashcardReminderTap(userInfo: [AnyHashable: Any]) {
        print("Handling flashcard reminder tap")
        
        NotificationCenter.default.post(name: .navigateToFlashcards, object: userInfo)
    }
    
    private func handleStreakReminderTap() {
        print("Handling streak reminder tap")
        
        NotificationCenter.default.post(name: .navigateToHome, object: nil)
    }
    
    private func handleSessionCompleteTap() {
        print("Handling session complete tap")
        
        NotificationCenter.default.post(name: .navigateToStats, object: nil)
    }
}


extension Notification.Name {
    static let navigateToTimer = Notification.Name("navigateToTimer")
    static let navigateToFlashcards = Notification.Name("navigateToFlashcards")
    static let navigateToHome = Notification.Name("navigateToHome")
    static let navigateToStats = Notification.Name("navigateToStats")
}


struct NotificationSetup: ViewModifier {
    @StateObject private var notificationService = NotificationService.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if notificationService.authorizationStatus == .notDetermined {
                    notificationService.requestPermission()
                }
                
                notificationService.scheduleSmartReminders()
            }
    }
}

extension View {
    func setupNotifications() -> some View {
        modifier(NotificationSetup())
    }
}
