//
//  CoreDataServiceTests.swift
//  NoeticaTests
//
//  Created by Abdul Rahuman on 2025-09-19.
//

import XCTest
import CoreData
@testable import Noetica

class CoreDataServiceTests: XCTestCase {
    
    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        let container = NSPersistentContainer(name: "Noetica")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test store")
        }
        
        testContext = container.viewContext
        coreDataService = CoreDataService.shared
    }
    
    override func tearDownWithError() throws {
        coreDataService = nil
        testContext = nil
    }
    
    func testCreateNoteSuccess() {
        let title = "Test Note"
        let body = "Test note body with some content"
        let subject = "Computer Science"
        
        let note = coreDataService.createNote(title: title, body: body, subject: subject)
        
        XCTAssertEqual(note.title, title)
        XCTAssertEqual(note.body, body)
        XCTAssertEqual(note.subject, subject)
        XCTAssertNotNil(note.id)
        XCTAssertNotNil(note.dateCreated)
        XCTAssertNotNil(note.dateModified)
    }
    
    func testCreateFlashcardWithDeck() {
        let deck = coreDataService.createDeck(name: "Physics Deck", subject: "Physics")
        let frontText = "What is Newton's first law?"
        let backText = "An object in motion stays in motion unless acted upon by a force"
        
        let flashcard = coreDataService.createFlashcard(frontText: frontText, backText: backText, deck: deck)
        
        XCTAssertEqual(flashcard.frontText, frontText)
        XCTAssertEqual(flashcard.backText, backText)
        XCTAssertEqual(flashcard.deck, deck)
        XCTAssertEqual(flashcard.easinessFactor, 2.5)
        XCTAssertEqual(flashcard.reviewCount, 0)
        XCTAssertEqual(flashcard.correctStreak, 0)
        XCTAssertNotNil(flashcard.id)
    }
    
    func testFetchNotesBySubject() {
        let mathSubject = "Mathematics"
        let physicsSubject = "Physics"
        
        _ = coreDataService.createNote(title: "Math Note 1", body: "Algebra content", subject: mathSubject)
        _ = coreDataService.createNote(title: "Math Note 2", body: "Geometry content", subject: mathSubject)
        _ = coreDataService.createNote(title: "Physics Note", body: "Mechanics content", subject: physicsSubject)
        
        let mathNotes = coreDataService.fetchNotes(for: mathSubject)
        let physicsNotes = coreDataService.fetchNotes(for: physicsSubject)
        let allNotes = coreDataService.fetchNotes()
        
        XCTAssertEqual(mathNotes.count, 2)
        XCTAssertEqual(physicsNotes.count, 1)
        XCTAssertGreaterThanOrEqual(allNotes.count, 3)
        
        for note in mathNotes {
            XCTAssertEqual(note.subject, mathSubject)
        }
    }
    
    func testCreateCalendarEventWithLinkedSession() {
        let title = "Study Mathematics"
        let description = "Focus on calculus problems"
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: 45, to: startTime)!
        let eventType = EventType.studySession
        let subject = "Mathematics"
        
        let event = coreDataService.createCalendarEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: eventType,
            subject: subject,
            autoCreateSession: true
        )
        
        XCTAssertEqual(event.title, title)
        XCTAssertEqual(event.description, description)
        XCTAssertEqual(event.startTime, startTime)
        XCTAssertEqual(event.endTime, endTime)
        XCTAssertEqual(event.type, eventType)
        XCTAssertEqual(event.subject, subject)
        XCTAssertNotNil(event.linkedSessionId)
        XCTAssertNotNil(event.id)
    }
    
    func testPomodoroSessionLifecycle() {
        let subjectOrDeck = "Advanced Physics"
        let sessionType = "studySession"
        let duration: Int16 = 25
        let startTime = Date()
        
        let session = coreDataService.createPomodoroSession(
            subjectOrDeck: subjectOrDeck,
            sessionType: sessionType,
            duration: duration,
            startTime: startTime
        )
        
        XCTAssertEqual(session.subjectOrDeck, subjectOrDeck)
        XCTAssertEqual(session.sessionType, sessionType)
        XCTAssertEqual(session.duration, duration)
        XCTAssertEqual(session.startTime, startTime)
        XCTAssertFalse(session.completed)
        XCTAssertNotNil(session.id)
        
        coreDataService.markPomodoroSessionCompleted(sessionId: session.id!)
        
        let completedSessions = coreDataService.fetchPomodoroSessions(completed: true)
        let completedSession = completedSessions.first { $0.id == session.id }
        
        XCTAssertNotNil(completedSession)
        XCTAssertTrue(completedSession!.completed)
        XCTAssertNotNil(completedSession!.endTime)
    }
    
    func testGetUniqueSubjects() {
        let subjects = ["Mathematics", "Physics", "Computer Science", "Mathematics"]
        
        for (index, subject) in subjects.enumerated() {
            _ = coreDataService.createNote(
                title: "Note \(index)",
                body: "Content for \(subject)",
                subject: subject
            )
        }
        
        _ = coreDataService.createDeck(name: "Biology Deck", subject: "Biology")
        
        let uniqueSubjects = coreDataService.getUniqueSubjects()
        
        XCTAssertTrue(uniqueSubjects.contains("Mathematics"))
        XCTAssertTrue(uniqueSubjects.contains("Physics"))
        XCTAssertTrue(uniqueSubjects.contains("Computer Science"))
        XCTAssertTrue(uniqueSubjects.contains("Biology"))
        
        let mathematicsCount = uniqueSubjects.filter { $0 == "Mathematics" }.count
        XCTAssertEqual(mathematicsCount, 1)
    }
    
    
    func testCreateNoteWithEmptyValues() {
        let note = coreDataService.createNote(title: "", body: "", subject: "")
        
        XCTAssertEqual(note.title, "")
        XCTAssertEqual(note.body, "")
        XCTAssertEqual(note.subject, "")
        XCTAssertNotNil(note.id)
    }
    
    func testFetchNotesForNonExistentSubject() {
        let notes = coreDataService.fetchNotes(for: "NonExistentSubject")
        XCTAssertTrue(notes.isEmpty)
    }
}
