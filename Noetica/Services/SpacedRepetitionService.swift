//
//  SpacedRepetitionService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import Foundation
import CoreData
import SwiftUI

enum ReviewQuality: Int, CaseIterable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
    
    var title: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
    
    var color: Color {
        switch self {
        case .again: return .red
        case .hard: return .orange
        case .good: return .blue
        case .easy: return .green
        }
    }
    
    var description: String {
        switch self {
        case .again: return "Completely forgot"
        case .hard: return "Difficult to recall"
        case .good: return "Recalled with effort"
        case .easy: return "Perfect recall"
        }
    }
}

class SpacedRepetitionService: ObservableObject {
    static let shared = SpacedRepetitionService()
    private let coreDataService = CoreDataService.shared
    
    private init() {}
    
    func reviewFlashcard(_ flashcard: Flashcard, quality: ReviewQuality) {
        print("🔍 SpacedRepetitionService: Starting review")
        let now = Date()
        
        flashcard.lastReviewDate = now
        flashcard.reviewCount += 1
        
        let (newEasiness, newRepetitions, newInterval) = calculateSM2(
            quality: quality.rawValue,
            easiness: flashcard.easinessFactor,
            repetitions: Int(flashcard.repetitions),
            previousInterval: Int(flashcard.interval)
        )
        
        flashcard.easinessFactor = newEasiness
        flashcard.repetitions = Int16(newRepetitions)
        flashcard.interval = Int16(newInterval)
        
        flashcard.nextReviewDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now
        
        if quality.rawValue >= 2 {
            flashcard.correctStreak += 1
        } else {
            flashcard.correctStreak = 0
        }
        
        flashcard.difficultyRating = Int16(5 - quality.rawValue)
        
        print("🔍 Updated flashcard properties")
        
        if let deck = flashcard.deck {
            updateDeckMastery(deck)
            print("🔍 Updated deck mastery")
        }
        
        coreDataService.save()
        print("✅ Flashcard reviewed and saved successfully")
    }



    
    private func calculateSM2(quality: Int, easiness: Double, repetitions: Int, previousInterval: Int) -> (Double, Int, Int) {
        var newEasiness = easiness
        var newRepetitions = repetitions
        var newInterval = previousInterval
        
        let qualityDiff = 5 - quality
        let qualityFactor = Double(qualityDiff)
        let innerCalc = 0.08 + qualityFactor * 0.02
        let outerCalc = qualityFactor * innerCalc
        let easinessChange = 0.1 - outerCalc
        newEasiness = newEasiness + easinessChange
        
        if newEasiness < 1.3 {
            newEasiness = 1.3
        }
        
        if quality < 3 {
            newRepetitions = 0
            newInterval = 1
        } else {
            newRepetitions += 1
            
            switch newRepetitions {
            case 1:
                newInterval = 1
            case 2:
                newInterval = 6
            default:
                newInterval = Int(Double(previousInterval) * newEasiness)
            }
        }
        
        return (newEasiness, newRepetitions, newInterval)
    }

    func getDueFlashcards(for deck: Deck? = nil) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        let now = Date()
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "nextReviewDate <= %@", now as NSDate)
        ]
        
        if let deck = deck {
            predicates.append(NSPredicate(format: "deck == %@", deck))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Flashcard.nextReviewDate, ascending: true),
            NSSortDescriptor(keyPath: \Flashcard.easinessFactor, ascending: true)
        ]
        
        do {
            return try CoreDataService.shared.context.fetch(request) // ← Change this
        } catch {
            print("Error fetching due flashcards: \(error)")
            return []
        }
    }

    func getNewFlashcards(for deck: Deck? = nil, limit: Int = 10) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "reviewCount == 0")
        ]
        
        if let deck = deck {
            predicates.append(NSPredicate(format: "deck == %@", deck))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: true)]
        request.fetchLimit = limit
        
        do {
            return try CoreDataService.shared.context.fetch(request) // ← Change this
        } catch {
            print("Error fetching new flashcards: \(error)")
            return []
        }
    }

    
    private func updateDeckMastery(_ deck: Deck) {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(format: "deck == %@", deck)
        
        do {
            let flashcards = try CoreDataService.shared.context.fetch(request)
            
            guard !flashcards.isEmpty else {
                deck.mastery = 0.0
                print("📊 Deck mastery updated: 0.0% (no cards)")
                return
            }
            
            let totalCards = flashcards.count
            
            let masteredCards = flashcards.filter { card in
                card.reviewCount >= 1 &&
                (card.correctStreak >= 1 || card.easinessFactor >= 2.5)
            }.count
            
            let newMastery = Double(masteredCards) / Double(totalCards)
            deck.mastery = newMastery
            
            print("📊 Deck '\(deck.name ?? "Unknown")' mastery updated: \(Int(newMastery * 100))% (\(masteredCards)/\(totalCards))")
            
        } catch {
            print("❌ Error fetching flashcards for mastery calculation: \(error)")
            deck.mastery = 0.0
        }
    }



    
    func getStudySessionStats(for deck: Deck? = nil) -> StudySessionStats {
        let dueCards = getDueFlashcards(for: deck)
        let newCards = getNewFlashcards(for: deck)
        
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        if let deck = deck {
            request.predicate = NSPredicate(format: "deck == %@", deck)
        }
        
        let totalCards = (try? CoreDataService.shared.context.count(for: request)) ?? 0 // ← Change this
        let reviewedToday = getTodayReviewCount(for: deck)
        
        return StudySessionStats(
            dueCards: dueCards.count,
            newCards: newCards.count,
            totalCards: totalCards,
            reviewedToday: reviewedToday
        )
    }

    private func getTodayReviewCount(for deck: Deck? = nil) -> Int {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "lastReviewDate >= %@ AND lastReviewDate < %@",
                       startOfDay as NSDate, endOfDay as NSDate)
        ]
        
        if let deck = deck {
            predicates.append(NSPredicate(format: "deck == %@", deck))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return (try? CoreDataService.shared.context.count(for: request)) ?? 0 // ← Change this
    }

}

struct StudySessionStats {
    let dueCards: Int
    let newCards: Int
    let totalCards: Int
    let reviewedToday: Int
    
    var hasCardsToReview: Bool {
        return dueCards > 0 || newCards > 0
    }
}
