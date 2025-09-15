//
//  NoeticaApp.swift
//  Noetica
//
//  Created by Abdul on 2025-08-22.
//

import SwiftUI

@main
struct NoeticaApp: App {
    let coreDataService = CoreDataService.shared
    let statsService = StatsService()

    var body: some Scene {
        WindowGroup {
            AuthView()
                .environment(\.managedObjectContext, coreDataService.context)
                .environmentObject(statsService)
        }
    }
}
