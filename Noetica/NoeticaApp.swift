//
//  NoeticaApp.swift
//  Noetica
//
//  Created by Abdul on 2025-08-22.
//

import SwiftUI

@main
struct NoeticaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
