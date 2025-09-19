//
//  SpacedRepetitionServiceTests.swift
//  NoeticaTests
//
//  Created by Abdul on 2025-09-19.
//

import XCTest
import CoreData
@testable import Noetica

class SpacedRepetitionServiceTests: XCTestCase {
    
    var spacedRepetitionService: SpacedRepetitionService!
    var coreDataService: CoreDataService!
    var testDeck: Deck!
    
    override func setUpWithError() throws {
        spacedRepetitionService = SpacedRepetitionService.shared
        coreDataService = CoreDataService.shared
        
        testDeck = coreDataService.createDeck(name: "Test Spaced Repetition", subject: "Testing")
    }
    
    override func tearDownWithError() throws {
        spacedRepetitionService = nil
        coreDataService = nil
        testDeck = nil
    }
    
    func testSM2AlgorithmWithGoodQuality() {
        let flashcard = coreDataService.createFlashcard(
            frontText: "What is the capital of France?",
            backText: "Paris",
            deck: testDeck
        )
        
        let initialEasiness = flashcard.easinessFactor
        let initialInterval = flashcard.interval
        let initialRepetitions = flashcard.repetitions
        let initialReviewCount = flashcard.reviewCount
        let initialCorrectStreak = flashcard.correctStreak
        
        spacedRepetitionService.reviewFlashcard(flashcard, quality: .good)
        
        XCTAssertEqual(flashcard.reviewCount, initialReviewCount + 1)
        XCTAssertNotNil(flashcard.lastReviewDate)
        XCTAssertNotNil(flashcard.nextReviewDate)
        XCTAssertGreaterThan(flashcard.easinessFactor, 0)
        XCTAssertEqual(flashcard.correctStreak, initialCorrectStreak + 1)
        
        XCTAssertEqual(flashcard.interval, 1)
        XCTAssertEqual(flashcard.repetitions, 0)
        
        XCTAssertNotEqual(flashcard.easinessFactor, initialEasiness)
    }

    
    func testSM2AlgorithmWithAgainQuality() {
        let flashcard = coreDataService.createFlashcard(
            frontText: "Complex question",
            backText: "Complex answer",
            deck: testDeck
        )
        
        flashcard.correctStreak = 5
        flashcard.repetitions = 3
        
        spacedRepetitionService.reviewFlashcard(flashcard, quality: .again)
        
        XCTAssertEqual(flashcard.reviewCount, 1)
        XCTAssertEqual(flashcard.correctStreak, 0)
        XCTAssertEqual(flashcard.repetitions, 0)
        XCTAssertEqual(flashcard.interval, 1)
    }
    
    
    
    func testGetDueFlashcards() {
        let overdueCard = coreDataService.createFlashcard(
            frontText: "Overdue Question",
            backText: "Overdue Answer",
            deck: testDeck
        )
        overdueCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        
        let dueCard = coreDataService.createFlashcard(
            frontText: "Due Question",
            backText: "Due Answer",
            deck: testDeck
        )
        dueCard.nextReviewDate = Date()
        
        let futureCard = coreDataService.createFlashcard(
            frontText: "Future Question",
            backText: "Future Answer",
            deck: testDeck
        )
        futureCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())
        
        coreDataService.save()
        
        let dueCards = spacedRepetitionService.getDueFlashcards(for: testDeck)
        
        XCTAssertGreaterThanOrEqual(dueCards.count, 2)
        XCTAssertTrue(dueCards.contains(overdueCard))
        XCTAssertTrue(dueCards.contains(dueCard))
        XCTAssertFalse(dueCards.contains(futureCard))
    }
    
    func testGetNewFlashcards() {
        let newCard1 = coreDataService.createFlashcard(
            frontText: "New Question 1",
            backText: "New Answer 1",
            deck: testDeck
        )
        
        let newCard2 = coreDataService.createFlashcard(
            frontText: "New Question 2",
            backText: "New Answer 2",
            deck: testDeck
        )
        
        let reviewedCard = coreDataService.createFlashcard(
            frontText: "Reviewed Question",
            backText: "Reviewed Answer",
            deck: testDeck
        )
        reviewedCard.reviewCount = 3
        
        coreDataService.save()
        
        let newCards = spacedRepetitionService.getNewFlashcards(for: testDeck, limit: 5)
        
        XCTAssertGreaterThanOrEqual(newCards.count, 2)
        XCTAssertTrue(newCards.contains(newCard1))
        XCTAssertTrue(newCards.contains(newCard2))
        XCTAssertFalse(newCards.contains(reviewedCard))
    }
    
    func testDeckMasteryCalculation() {
        let masteredCard = coreDataService.createFlashcard(
            frontText: "Mastered Question",
            backText: "Mastered Answer",
            deck: testDeck
        )
        masteredCard.reviewCount = 5
        masteredCard.correctStreak = 3
        masteredCard.easinessFactor = 2.8
        
        let strugglingCard = coreDataService.createFlashcard(
            frontText: "Struggling Question",
            backText: "Struggling Answer",
            deck: testDeck
        )
        strugglingCard.reviewCount = 2
        strugglingCard.correctStreak = 0
        strugglingCard.easinessFactor = 1.5
        
        coreDataService.save()
        
        spacedRepetitionService.reviewFlashcard(masteredCard, quality: .easy)
        
        XCTAssertGreaterThanOrEqual(testDeck.mastery, 0.0)
        XCTAssertLessThanOrEqual(testDeck.mastery, 1.0)
    }
    
    func testStudySessionStatsBasic() {
        let freshDeck = coreDataService.createDeck(name: "Stats Test Deck", subject: "Testing")
        
        let emptyStats = spacedRepetitionService.getStudySessionStats(for: freshDeck)
        
        XCTAssertEqual(emptyStats.totalCards, 0)
        XCTAssertEqual(emptyStats.newCards, 0)
        XCTAssertEqual(emptyStats.dueCards, 0)
        XCTAssertFalse(emptyStats.hasCardsToReview)
        
        let card1 = coreDataService.createFlashcard(frontText: "Q1", backText: "A1", deck: freshDeck)
        let card2 = coreDataService.createFlashcard(frontText: "Q2", backText: "A2", deck: freshDeck)
        coreDataService.save()
        
        let updatedStats = spacedRepetitionService.getStudySessionStats(for: freshDeck)
        XCTAssertEqual(updatedStats.totalCards, 2)
        XCTAssertTrue(updatedStats.totalCards > 0)
        XCTAssertTrue(updatedStats.hasCardsToReview)
        
        coreDataService.deleteFlashcard(card1)
        coreDataService.deleteFlashcard(card2)
        coreDataService.deleteDeck(freshDeck)
        coreDataService.save()
    }


    
    
    func testReviewNonExistentFlashcard() {
        let flashcard = coreDataService.createFlashcard(
            frontText: "Test",
            backText: "Test",
            deck: testDeck
        )
        
        spacedRepetitionService.reviewFlashcard(flashcard, quality: .easy)
        XCTAssertGreaterThan(flashcard.reviewCount, 0)
    }
    
    func testEmptyDeckStats() {
        let emptyDeck = coreDataService.createDeck(name: "Empty Deck", subject: "Test")
        
        let stats = spacedRepetitionService.getStudySessionStats(for: emptyDeck)
        
        XCTAssertEqual(stats.totalCards, 0)
        XCTAssertEqual(stats.newCards, 0)
        XCTAssertEqual(stats.dueCards, 0)
        XCTAssertFalse(stats.hasCardsToReview)
    }
}
