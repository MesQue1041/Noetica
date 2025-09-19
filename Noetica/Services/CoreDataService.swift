//
//  CoreDataService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import Foundation
import CoreData
import SwiftUI
import UserNotifications

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Noetica")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                print("Core Data error: \(error)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Core Data initialized successfully")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        context.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("Core Data saved successfully")
            } catch {
                print("Failed to save Core Data: \(error)")
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    
    func createCalendarEvent(
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
        type: EventType,
        subject: String? = nil,
        deckName: String? = nil,
        autoCreateSession: Bool = true
    ) -> CalendarEvent {
        let event = CalendarEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: type,
            subject: subject,
            deckName: deckName
        )
        
        if autoCreateSession {
            let linkedSession = createPomodoroSession(
                subjectOrDeck: subject ?? deckName ?? title,
                sessionType: type.rawValue,
                duration: Int16((endTime.timeIntervalSince(startTime)) / 60),
                linkedEventId: event.id,
                startTime: startTime
            )
            
            var updatedEvent = event
            updatedEvent.linkedSessionId = linkedSession.id
            
            saveCalendarEvent(updatedEvent)
            
            NotificationService.shared.scheduleSessionReminder(for: updatedEvent, minutesBefore: 10)
            NotificationService.shared.scheduleSessionStartNotification(for: updatedEvent)
            
            print("Created calendar event with linked session and notifications")
            return updatedEvent
        } else {
            saveCalendarEvent(event)
            NotificationService.shared.scheduleSessionReminder(for: event, minutesBefore: 10)
            NotificationService.shared.scheduleSessionStartNotification(for: event) 
            return event
        }
    }

    
    func createQuickPomodoroEvent(
        subject: String? = nil,
        deckName: String? = nil,
        duration: Int = 25
    ) -> CalendarEvent {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: duration, to: now) ?? now
        
        let eventType: EventType = subject != nil ? .studySession : .flashcards
        let title = subject != nil ? "Study Session: \(subject!)" : "Flashcard Review: \(deckName ?? "Unknown Deck")"
        
        return createCalendarEvent(
            title: title,
            description: "Quick session started from Pomodoro timer",
            startTime: now,
            endTime: endTime,
            type: eventType,
            subject: subject,
            deckName: deckName,
            autoCreateSession: true
        )
    }
    
    private func saveCalendarEvent(_ event: CalendarEvent) {
        var events = fetchCalendarEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "calendar_events")
        }
    }
    
    func fetchCalendarEvents(for date: Date? = nil) -> [CalendarEvent] {
        guard let data = UserDefaults.standard.data(forKey: "calendar_events"),
              let events = try? JSONDecoder().decode([CalendarEvent].self, from: data) else {
            return []
        }
        
        if let date = date {
            let calendar = Calendar.current
            return events.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
        }
        
        return events
    }
    
    func markEventCompleted(_ event: CalendarEvent) {
        var updatedEvent = event
        updatedEvent.isCompleted = true
        saveCalendarEvent(updatedEvent)
        
        NotificationService.shared.cancelEventNotifications(for: event)
        
        if let linkedSessionId = event.linkedSessionId {
            markPomodoroSessionCompleted(sessionId: linkedSessionId)
        }
        
        let sessionType = event.type.rawValue
        let subject = event.subject ?? event.deckName
        NotificationService.shared.sendSessionCompletionNotification(sessionType: sessionType, subject: subject)
        
        print("Event completed with notifications handled")
    }
    
    
    func createPomodoroSession(
        subjectOrDeck: String,
        sessionType: String,
        duration: Int16,
        linkedEventId: UUID? = nil,
        startTime: Date = Date()
    ) -> PomodoroSession {
        let session = PomodoroSession(context: context)
        session.id = UUID()
        session.subjectOrDeck = subjectOrDeck
        session.sessionType = sessionType
        session.duration = duration
        session.startTime = startTime
        session.endTime = Calendar.current.date(byAdding: .minute, value: Int(duration), to: startTime)
        session.completed = false
        session.linkedCalendarEventId = linkedEventId
        
        save()
        print("Created Pomodoro session linked to event: \(linkedEventId?.uuidString ?? "none")")
        return session
    }
    
    func markPomodoroSessionCompleted(sessionId: UUID) {
        let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
        
        do {
            let sessions = try context.fetch(request)
            if let session = sessions.first {
                session.completed = true
                session.endTime = Date()
                save()
                print("Pomodoro session marked as completed")
            }
        } catch {
            print("Error marking session completed: \(error)")
        }
    }
    
    func fetchPomodoroSessions(completed: Bool? = nil) -> [PomodoroSession] {
        let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
        
        if let completed = completed {
            request.predicate = NSPredicate(format: "completed == %@", NSNumber(value: completed))
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching Pomodoro sessions: \(error)")
            return []
        }
    }
    
    func fetchCompletedSessions(from startDate: Date, to endDate: Date) -> [PomodoroSession] {
        let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
        request.predicate = NSPredicate(format: "completed == %@ AND startTime >= %@ AND startTime <= %@",
                                      NSNumber(value: true), startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completed sessions: \(error)")
            return []
        }
    }
    
    
    func createNote(title: String, body: String, subject: String? = nil, tags: String? = nil) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.title = title
        note.body = body
        note.subject = subject
        note.tags = tags
        note.dateCreated = Date()
        note.dateModified = Date()
        
        save()
        return note
    }
    
    func fetchNotes(for subject: String? = nil) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        
        if let subject = subject {
            request.predicate = NSPredicate(format: "subject == %@", subject)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "dateModified", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }
    
    func createDeck(name: String, subject: String) -> Deck {
        let deck = Deck(context: context)
        deck.id = UUID()
        deck.name = name
        deck.subject = subject
        deck.mastery = 0.0
        
        save()
        return deck
    }
    
    func fetchDecks() -> [Deck] {
        let request: NSFetchRequest<Deck> = Deck.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching decks: \(error)")
            return []
        }
    }
    
    func createFlashcard(frontText: String, backText: String, deck: Deck) -> Flashcard {
        let flashcard = Flashcard(context: context)
        flashcard.id = UUID()
        flashcard.frontText = frontText
        flashcard.backText = backText
        flashcard.deck = deck
        flashcard.dateCreated = Date()
        flashcard.lastReviewDate = nil
        flashcard.nextReviewDate = Date()
        flashcard.reviewCount = 0
        flashcard.correctStreak = 0
        flashcard.easinessFactor = 2.5
        flashcard.interval = 1
        flashcard.repetitions = 0
        flashcard.difficultyRating = 5
        
        save()
        return flashcard
    }
    
    func fetchFlashcards(for deck: Deck? = nil) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        
        if let deck = deck {
            request.predicate = NSPredicate(format: "deck == %@", deck)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching flashcards: \(error)")
            return []
        }
    }
    
    func getUniqueSubjects() -> [String] {
        let noteRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let deckRequest: NSFetchRequest<Deck> = Deck.fetchRequest()
        
        var subjects = Set<String>()
        
        do {
            let notes = try context.fetch(noteRequest)
            let decks = try context.fetch(deckRequest)
            
            for note in notes {
                if let subject = note.subject, !subject.isEmpty {
                    subjects.insert(subject)
                }
            }
            
            for deck in decks {
                if let subject = deck.subject, !subject.isEmpty {
                    subjects.insert(subject)
                }
            }
        } catch {
            print("Error fetching subjects: \(error)")
        }
        
        return Array(subjects).sorted()
    }
    
    func deleteNote(_ note: Note) {
        context.delete(note)
        save()
    }
    
    func deleteDeck(_ deck: Deck) {
        context.delete(deck)
        save()
    }
    
    func deleteFlashcard(_ flashcard: Flashcard) {
        context.delete(flashcard)
        save()
    }
}
