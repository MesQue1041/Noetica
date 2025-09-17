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
    let statsService = StatsService()
    @StateObject private var authService = AuthService()  
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environment(\.managedObjectContext, coreDataService.context)
                    .environmentObject(statsService)
            } else {
                AuthView()
                    .environmentObject(authService)
                    .environment(\.managedObjectContext, coreDataService.context)
                    .environmentObject(statsService)
            }
        }
    }
}
