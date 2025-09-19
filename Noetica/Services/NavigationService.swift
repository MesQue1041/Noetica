//
//  NavigationService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-19.
//

import Foundation
import SwiftUI

class NavigationService: ObservableObject {
    static let shared = NavigationService()
    
    @Published var selectedTab: Int = 0
    @Published var shouldNavigateToTimer: Bool = false
    @Published var pendingTimerEvent: CalendarEvent?
    
    private init() {}
    
    func navigateToTimer(with event: CalendarEvent) {
        pendingTimerEvent = event
        
        shouldNavigateToTimer = true
    }

    
    func clearNavigation() {
        shouldNavigateToTimer = false
        pendingTimerEvent = nil
    }
}
