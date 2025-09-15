//
//  CoreDataService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import Foundation
import CoreData
import SwiftUI

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Noetica")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    // Note Operations
    func createNote(title: String, body: String, subject: String) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.title = title
        note.body = body
        note.subject = subject.isEmpty ? nil : subject
        note.dateCreated = Date()
        note.dateModified = Date()
        save()
        return note
    }
    
    func fetchNotes() -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateModified, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch notes: \(error)")
            return []
        }
    }
    
    func fetchNotes(for subject: String) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "subject == %@", subject)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateModified, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch notes for subject: \(error)")
            return []
        }
    }
    
    func deleteNote(_ note: Note) {
        context.delete(note)
        save()
    }
    
    // Deck Operations
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
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Deck.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch decks: \(error)")
            return []
        }
    }
    
    func deleteDeck(_ deck: Deck) {
        context.delete(deck)
        save()
    }
    
    //Flashcard Operations
    func createFlashcard(front: String, back: String, deck: Deck? = nil) -> Flashcard {
        let flashcard = Flashcard(context: context)
        flashcard.id = UUID()
        flashcard.frontText = front
        flashcard.backText = back
        flashcard.dateCreated = Date()
        flashcard.dateModified = Date()
        flashcard.difficultyRating = 0
        flashcard.deck = deck
        save()
        return flashcard
    }
    
    func fetchFlashcards() -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch flashcards: \(error)")
            return []
        }
    }
    
    func fetchFlashcards(for deck: Deck) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(format: "deck == %@", deck)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch flashcards for deck: \(error)")
            return []
        }
    }
    
    func deleteFlashcard(_ flashcard: Flashcard) {
        context.delete(flashcard)
        save()
    }
    
    // Subject Operations
    func getUniqueSubjects() -> [String] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["subject"]
        
        do {
            let notes = try context.fetch(request)
            let subjects = notes.compactMap { $0.subject?.trimmingCharacters(in: .whitespacesAndNewlines) }
            return Array(Set(subjects)).filter { !$0.isEmpty }.sorted()
        } catch {
            print("Failed to fetch unique subjects: \(error)")
            return []
        }
    }
    
    // MARK: - Pomodoro Session Operations
    func createPomodoroSession(subjectOrDeck: String, sessionType: String, duration: Int16) -> PomodoroSession {
        let session = PomodoroSession(context: context)
        session.id = UUID()
        session.subjectOrDeck = subjectOrDeck
        session.sessionType = sessionType
        session.duration = duration
        session.startTime = Date()
        session.completed = false
        save()
        return session
    }
    
    func completePomodoroSession(_ session: PomodoroSession) {
        session.endTime = Date()
        session.completed = true
        save()
    }
    
    func fetchCompletedSessions(from startDate: Date, to endDate: Date) -> [PomodoroSession] {
        let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
        request.predicate = NSPredicate(format: "completed == YES AND startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PomodoroSession.startTime, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch completed sessions: \(error)")
            return []
        }
    }
}
