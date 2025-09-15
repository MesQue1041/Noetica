//
//  DataModels.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let startTime: Date
    let endTime: Date
    let type: EventType
    let color: Color
    
    enum EventType: String, CaseIterable {
        case study = "Study Session"
        case pomodoro = "Pomodoro"
        case flashcards = "Flashcards"
        case breakTime = "Break"
        case meeting = "Meeting"
        case reminder = "Reminder"
        
        var icon: String {
            switch self {
            case .study: return "book.fill"
            case .pomodoro: return "timer.circle.fill"
            case .flashcards: return "rectangle.stack.fill"
            case .breakTime: return "cup.and.saucer.fill"
            case .meeting: return "person.2.fill"
            case .reminder: return "bell.fill"
            }
        }
        
        var defaultColor: Color {
            switch self {
            case .study: return .blue
            case .pomodoro: return .red
            case .flashcards: return .green
            case .breakTime: return .orange
            case .meeting: return .purple
            case .reminder: return .yellow
            }
        }
    }
}

enum PomodoroSessionType: String, CaseIterable, Identifiable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var id: String { rawValue }
    var duration: Int {
        switch self {
        case .work: return 10
        case .shortBreak: return 5
        case .longBreak: return 8 
        }
    }
    
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .shortBreak: return .green
        case .longBreak: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
}

enum CreateMode: String, CaseIterable {
    case note = "Note"
    case flashcard = "Flashcard"
    
    var icon: String {
        switch self {
        case .note: return "doc.text.fill"
        case .flashcard: return "rectangle.stack.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .note: return .blue
        case .flashcard: return .purple
        }
    }
}

struct StudySession: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let type: SessionType
    let subject: String
}

enum SessionType {
    case pomodoro, flashcard
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .flashcard: return "rectangle.stack"
        }
    }
    
    var color: Color {
        switch self {
        case .pomodoro: return .orange
        case .flashcard: return .purple
        }
    }
}

struct StudyRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
    let priority: Priority
    let type: RecommendationType
}

enum Priority {
    case high, medium, low
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

enum RecommendationType {
    case flashcard, notes, pomodoro
    
    var icon: String {
        switch self {
        case .flashcard: return "rectangle.stack"
        case .notes: return "doc.text"
        case .pomodoro: return "timer"
        }
    }
}

enum ExplorerMode: CaseIterable {
    case notes, decks
    
    var title: String {
        switch self {
        case .notes: return "Notes"
        case .decks: return "Decks"
        }
    }
    
    var icon: String {
        switch self {
        case .notes: return "doc.text"
        case .decks: return "rectangle.stack"
        }
    }
}

struct ExplorerSubject: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let noteCount: Int
    let imageName: String
}

struct ExplorerDeck: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let cardCount: Int
    let masteryLevel: Double
}

struct StudyStats {
    let totalNotes: Int
    let totalFlashcards: Int
    let totalDecks: Int
    let totalStudyHours: Double
    let currentStreak: Int
    let averageMastery: Double
}

extension Date {
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
}

extension Color {
    static func randomStudyColor() -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .indigo, .red, .cyan]
        return colors.randomElement() ?? .blue
    }
}
