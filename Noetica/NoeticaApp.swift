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
    
    init() {
        FirebaseApp.configure()
        
        _ = CoreDataService.shared.context
        print("Core Data initialized successfully")
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
