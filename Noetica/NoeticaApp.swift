//
//  NoeticaApp.swift
//  Noetica
//
//  Created by Abdul on 2025-08-22.
//

import SwiftUI
import Firebase

@main
struct NoeticaApp: App {
    let coreDataService = CoreDataService.shared
    @StateObject private var statsService = StatsService()
    @StateObject private var authService = AuthService()
    @StateObject private var notificationService = NotificationService.shared
    
    init() {
        FirebaseApp.configure()
        
        _ = CoreDataService.shared.context
        print("Core Data initialized successfully")
        
        setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environment(\.managedObjectContext, coreDataService.context)
                    .environmentObject(statsService)
                    .environmentObject(notificationService)
                    .setupNotifications()
                    .onReceive(NotificationCenter.default.publisher(for: .navigateToTimer)) { notification in
                        handleNotificationNavigation(.navigateToTimer, userInfo: notification.object)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .navigateToFlashcards)) { notification in
                        handleNotificationNavigation(.navigateToFlashcards, userInfo: notification.object)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { notification in
                        handleNotificationNavigation(.navigateToHome, userInfo: notification.object)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .navigateToStats)) { notification in
                        handleNotificationNavigation(.navigateToStats, userInfo: notification.object)
                    }
            } else {
                AuthView()
                    .environmentObject(authService)
                    .environment(\.managedObjectContext, coreDataService.context)
                    .environmentObject(statsService)
                    .environmentObject(notificationService)
            }
        }
    }
    
    private func setupNotificationCategories() {
        let studyAction = UNNotificationAction(identifier: "START_STUDY", title: "Start Now", options: .foreground)
        let flashcardAction = UNNotificationAction(identifier: "REVIEW_CARDS", title: "Review", options: .foreground)
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Snooze 10m", options: [])
        
        let studyCategory = UNNotificationCategory(
            identifier: "STUDY_REMINDER",
            actions: [studyAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        let flashcardCategory = UNNotificationCategory(
            identifier: "FLASHCARD_REMINDER",
            actions: [flashcardAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        let spacedRepetitionCategory = UNNotificationCategory(
            identifier: "SPACED_REPETITION",
            actions: [flashcardAction],
            intentIdentifiers: [],
            options: []
        )
        
        let dailyReviewCategory = UNNotificationCategory(
            identifier: "DAILY_REVIEW",
            actions: [flashcardAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            studyCategory, flashcardCategory, spacedRepetitionCategory, dailyReviewCategory
        ])
    }
    
    private func handleNotificationNavigation(_ type: Notification.Name, userInfo: Any?) {
        print("Handling navigation for: \(type)")
        
        switch type {
        case .navigateToTimer:
            print("Navigate to timer with info: \(String(describing: userInfo))")
        case .navigateToFlashcards:
            print("Navigate to flashcards with info: \(String(describing: userInfo))")
        case .navigateToHome:
            print("Navigate to home")
        case .navigateToStats:
            print("Navigate to stats")
        default:
            break
        }
    }
}
