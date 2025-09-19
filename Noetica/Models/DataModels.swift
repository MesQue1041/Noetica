//
//  DataModels.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Equatable, Codable {   // These are for the calendar
    let id: UUID
    let title: String
    let description: String
    let startTime: Date
    let endTime: Date
    let type: EventType
    let color: Color?
    let subject: String?
    let deckName: String?
    var linkedSessionId: UUID?
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, description: String, startTime: Date, endTime: Date, type: EventType, color: Color? = nil, subject: String? = nil, deckName: String? = nil, linkedSessionId: UUID? = nil, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.color = color ?? type.defaultColor
        self.subject = subject
        self.deckName = deckName
        self.linkedSessionId = linkedSessionId
        self.isCompleted = isCompleted
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, startTime, endTime, type, subject, deckName, linkedSessionId, isCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        type = try container.decode(EventType.self, forKey: .type)
        subject = try container.decodeIfPresent(String.self, forKey: .subject)
        deckName = try container.decodeIfPresent(String.self, forKey: .deckName)
        linkedSessionId = try container.decodeIfPresent(UUID.self, forKey: .linkedSessionId)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        color = type.defaultColor
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(subject, forKey: .subject)
        try container.encodeIfPresent(deckName, forKey: .deckName)
        try container.encodeIfPresent(linkedSessionId, forKey: .linkedSessionId)
        try container.encode(isCompleted, forKey: .isCompleted)
    }
}

enum EventType: String, CaseIterable, Codable {
    case studySession = "Study Session"
    case flashcards = "Flashcards"
    
    var icon: String {
        switch self {
        case .studySession: return "book.fill"
        case .flashcards: return "rectangle.stack.fill"
        }
    }
    
    var defaultColor: Color {
        switch self {
        case .studySession: return .blue
        case .flashcards: return .green
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
        case .work: return 25
        case .shortBreak: return 5
        case .longBreak: return 15
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
    let id: UUID
    let title: String
    let time: String
    let type: SessionType
    let subject: String
    
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
}

struct StudyRecommendation: Identifiable {
    let id: UUID
    let title: String
    let reason: String
    let priority: Priority
    let type: RecommendationType
    let subject: String?
    let deckName: String?
    
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
    let id: UUID
    let name: String
    let color: Color
    let noteCount: Int
    let imageName: String?
}

struct ExplorerDeck: Identifiable {
    let id: UUID
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
