//
//  NoeticaTests.swift
//  NoeticaTests
//
//  Created by Abdul on 2025-08-22.
//

import Testing
import CoreData
import XCTest
@testable import Noetica

@MainActor
struct NoeticaTests {
    
    
    private func createInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Noetica")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        return container.viewContext
    }
    
    
    @Test("CoreData - Create Note")
    func testCreateNote() async throws {
        let context = createInMemoryContext()
        let service = CoreDataService.shared
        
        let note = service.createNote(
            title: "Test Note",
            body: "This is a test note body",
            subject: "Computer Science"
        )
        
        #expect(note.title == "Test Note")
        #expect(note.body == "This is a test note body")
        #expect(note.subject == "Computer Science")
        #expect(note.id != nil)
        #expect(note.dateCreated != nil)
    }
    
    @Test("CoreData - Create Flashcard")
    func testCreateFlashcard() async throws {
        let context = createInMemoryContext()
        let service = CoreDataService.shared
        
        let deck = service.createDeck(name: "Test Deck", subject: "Math")
        
        let flashcard = service.createFlashcard(
            frontText: "What is 2+2?",
            backText: "4",
            deck: deck
        )
        
        #expect(flashcard.frontText == "What is 2+2?")
        #expect(flashcard.backText == "4")
        #expect(flashcard.deck == deck)
        #expect(flashcard.easinessFactor == 2.5)
        #expect(flashcard.reviewCount == 0)
    }
    
    @Test("CoreData - Fetch Notes by Subject")
    func testFetchNotesBySubject() async throws {
        let service = CoreDataService.shared
        
        _ = service.createNote(title: "Math Note 1", body: "Content 1", subject: "Math")
        _ = service.createNote(title: "Math Note 2", body: "Content 2", subject: "Math")
        _ = service.createNote(title: "Science Note", body: "Content 3", subject: "Science")
        
        let mathNotes = service.fetchNotes(for: "Math")
        let scienceNotes = service.fetchNotes(for: "Science")
        
        #expect(mathNotes.count == 2)
        #expect(scienceNotes.count == 1)
        #expect(mathNotes.first?.subject == "Math")
    }
    
    
    @Test("Spaced Repetition - SM2 Algorithm")
    func testSM2Algorithm() async throws {
        let service = SpacedRepetitionService.shared
        let context = createInMemoryContext()
        
        let deck = CoreDataService.shared.createDeck(name: "Test", subject: "Test")
        let flashcard = CoreDataService.shared.createFlashcard(
            frontText: "Test Question",
            backText: "Test Answer",
            deck: deck
        )
        
        service.reviewFlashcard(flashcard, quality: .good)
        
        #expect(flashcard.reviewCount == 1)
        #expect(flashcard.lastReviewDate != nil)
        #expect(flashcard.nextReviewDate != nil)
        #expect(flashcard.easinessFactor >= 1.3)
    }
    
    @Test("Spaced Repetition - Get Due Flashcards")
    func testGetDueFlashcards() async throws {
        let service = SpacedRepetitionService.shared
        let deck = CoreDataService.shared.createDeck(name: "Test Deck", subject: "Test")
        
        let flashcard1 = CoreDataService.shared.createFlashcard(
            frontText: "Question 1",
            backText: "Answer 1",
            deck: deck
        )
        
        flashcard1.nextReviewDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        let dueCards = service.getDueFlashcards(for: deck)
        
        #expect(dueCards.count >= 1)
        #expect(dueCards.contains(flashcard1))
    }
    
    
    @Test("ML Classification - Basic Text Classification")
    func testMLTextClassification() async throws {
        let classifier = MLTextClassifier.shared
        
        let csText = "Swift programming language variables and functions"
        let result = classifier.classifyText(csText)
        
        //just making sure that the function works and it gives a proper result
        #expect(result != nil)
        #expect(!result.isEmpty)
    }
    
    
    @Test("Calendar - Create Event")
    func testCreateCalendarEvent() async throws {
        let service = CoreDataService.shared
        
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime)!
        
        let event = service.createCalendarEvent(
            title: "Study Session",
            description: "Test study session",
            startTime: startTime,
            endTime: endTime,
            type: .studySession,
            subject: "Math"
        )
        
        #expect(event.title == "Study Session")
        #expect(event.type == .studySession)
        #expect(event.subject == "Math")
        #expect(event.startTime == startTime)
        #expect(event.endTime == endTime)
    }
    
    
    @Test("Pomodoro - Create Session")
    func testCreatePomodoroSession() async throws {
        let service = CoreDataService.shared
        
        let session = service.createPomodoroSession(
            subjectOrDeck: "Math",
            sessionType: "studySession",
            duration: 25,
            startTime: Date()
        )
        
        #expect(session.subjectOrDeck == "Math")
        #expect(session.sessionType == "studySession")
        #expect(session.duration == 25)
        #expect(session.completed == false)
        #expect(session.id != nil)
    }
    
    @Test("Pomodoro - Mark Session Completed")
    func testMarkPomodoroSessionCompleted() async throws {
        let service = CoreDataService.shared
        
        let session = service.createPomodoroSession(
            subjectOrDeck: "Science",
            sessionType: "studySession",
            duration: 25,
            startTime: Date()
        )
        
        service.markPomodoroSessionCompleted(sessionId: session.id!)
        
        let sessions = service.fetchPomodoroSessions(completed: true)
        let completedSession = sessions.first { $0.id == session.id }
        
        #expect(completedSession?.completed == true)
        #expect(completedSession?.endTime != nil)
    }
    
    
    @Test("Stats - Calculate Study Stats")
    func testStudyStatsCalculation() async throws {
        let service = CoreDataService.shared
        
        let initialNotes = service.fetchNotes().count
        let initialFlashcards = service.fetchFlashcards().count
        let initialDecks = service.fetchDecks().count
        
        let testDeck = service.createDeck(name: "Test Stats Deck", subject: "Testing Stats")
        let testFlashcard = service.createFlashcard(frontText: "Test Q", backText: "Test A", deck: testDeck)
        let testNote = service.createNote(title: "Test Stats Note", body: "Test content", subject: "Testing Stats")
        
        service.save()
        
        let finalNotes = service.fetchNotes().count
        let finalFlashcards = service.fetchFlashcards().count
        let finalDecks = service.fetchDecks().count
        
        #expect(finalNotes == initialNotes + 1)
        #expect(finalFlashcards == initialFlashcards + 1)
        #expect(finalDecks == initialDecks + 1)
        
        service.deleteNote(testNote)
        service.deleteFlashcard(testFlashcard)
        service.deleteDeck(testDeck)
        service.save()
        
        let cleanupNotes = service.fetchNotes().count
        let cleanupFlashcards = service.fetchFlashcards().count
        let cleanupDecks = service.fetchDecks().count
        
        #expect(cleanupNotes == initialNotes)
        #expect(cleanupFlashcards == initialFlashcards)
        #expect(cleanupDecks == initialDecks)
    }

    
    @Test("Error Handling - Invalid Flashcard Review")
    func testInvalidFlashcardReview() async throws {
        let service = SpacedRepetitionService.shared
        let deck = CoreDataService.shared.createDeck(name: "Test", subject: "Test")
        let flashcard = CoreDataService.shared.createFlashcard(
            frontText: "Test",
            backText: "Test",
            deck: deck
        )
        
        let initialReviewCount = flashcard.reviewCount
        
        
        service.reviewFlashcard(flashcard, quality: .again)
        
        #expect(flashcard.reviewCount == initialReviewCount + 1)
        #expect(flashcard.correctStreak == 0)
    }
    
    @Test("Edge Case - Empty Subject Fetch")
    func testEmptySubjectFetch() async throws {
        let service = CoreDataService.shared
        
        let notes = service.fetchNotes(for: "NonExistentSubject")
        
        #expect(notes.isEmpty)
    }
    
    @Test("Edge Case - Deck Mastery Calculation")
    func testDeckMasteryCalculation() async throws {
        let service = SpacedRepetitionService.shared
        let deck = CoreDataService.shared.createDeck(name: "Mastery Test", subject: "Test")
        
        let flashcard = CoreDataService.shared.createFlashcard(
            frontText: "Mastery Question",
            backText: "Mastery Answer",
            deck: deck
        )
        
        service.reviewFlashcard(flashcard, quality: .easy)
        
        #expect(deck.mastery >= 0.0)
        #expect(deck.mastery <= 1.0)
    }
}
