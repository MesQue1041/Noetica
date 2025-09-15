//
//  StatsService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import Foundation
import CoreData
import SwiftUI

class StatsService: ObservableObject {
    private let coreDataService = CoreDataService.shared
    
    @Published var studyStats = StudyStats(
        totalNotes: 0,
        totalFlashcards: 0,
        totalDecks: 0,
        totalStudyHours: 0.0,
        currentStreak: 0,
        averageMastery: 0.0
    )
    
    init() {
        updateStats()
    }
    
    func updateStats() {
        let notes = coreDataService.fetchNotes()
        let flashcards = coreDataService.fetchFlashcards()
        let decks = coreDataService.fetchDecks()
        
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        let completedSessions = coreDataService.fetchCompletedSessions(from: weekAgo, to: today)
        let totalMinutes = completedSessions.reduce(0) { $0 + Int($1.duration) }
        let studyHours = Double(totalMinutes) / 60.0
        
        let averageMastery = decks.isEmpty ? 0.0 : decks.reduce(0.0) { $0 + $1.mastery } / Double(decks.count)
        
        let currentStreak = calculateStudyStreak()
        
        DispatchQueue.main.async {
            self.studyStats = StudyStats(
                totalNotes: notes.count,
                totalFlashcards: flashcards.count,
                totalDecks: decks.count,
                totalStudyHours: studyHours,
                currentStreak: currentStreak,
                averageMastery: averageMastery
            )
        }
    }
    
    private func calculateStudyStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        for i in 0..<30 {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let sessions = coreDataService.fetchCompletedSessions(from: dayStart, to: dayEnd)
            
            if !sessions.isEmpty {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if i == 0 {
                break
            } else {
                break
            }
        }
        
        return streak
    }
    
    func getSubjectStats() -> [(subject: String, noteCount: Int, color: Color)] {
        let subjects = coreDataService.getUniqueSubjects()
        return subjects.map { subject in
            let noteCount = coreDataService.fetchNotes(for: subject).count
            return (subject: subject, noteCount: noteCount, color: Color.randomStudyColor())
        }
    }
    
    func getDeckStats() -> [(deck: Deck, flashcardCount: Int)] {
        let decks = coreDataService.fetchDecks()
        return decks.map { deck in
            let flashcardCount = coreDataService.fetchFlashcards(for: deck).count
            return (deck: deck, flashcardCount: flashcardCount)
        }
    }
}
