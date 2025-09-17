//
//  AdvancedFlashcardReviewView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-15.
//

import SwiftUI

struct AdvancedFlashcardReviewView: View {
    let deck: Deck
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var spacedRepetition = SpacedRepetitionService.shared
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var statsService: StatsService
    
    @State private var currentCardIndex = 0
    @State private var showAnswer = false
    @State private var reviewCards: [Flashcard] = []
    @State private var sessionStats: StudySessionStats = StudySessionStats(dueCards: 0, newCards: 0, totalCards: 0, reviewedToday: 0)
    @State private var cardsReviewedInSession = 0
    @State private var showCompletionAlert = false
    
    var currentCard: Flashcard? {
        guard currentCardIndex < reviewCards.count else { return nil }
        return reviewCards[currentCardIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let card = currentCard {
                    ReviewHeaderView(
                        currentIndex: currentCardIndex + 1,
                        totalCards: reviewCards.count,
                        deck: deck
                    )
                    
                    FlashcardDisplayView(
                        flashcard: card,
                        showAnswer: $showAnswer
                    )
                    
                    if showAnswer {
                        QualityButtonsView { quality in
                            reviewCard(quality: quality)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        ShowAnswerButton {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAnswer = true
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else {
                    EmptyReviewView(deck: deck)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Session Complete! 🎉", isPresented: $showCompletionAlert) {
            Button("Continue Studying") {
                startNewSession()
            }
            Button("Finish") {
                showCompletionAlert = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }
        } message: {
            Text("Great job! You've reviewed \(cardsReviewedInSession) cards. Ready for more?")
        }

        .onAppear {
            startNewSession()
        }
    }
    
    private func startNewSession() {
        sessionStats = spacedRepetition.getStudySessionStats(for: deck)
        
        var cards = spacedRepetition.getDueFlashcards(for: deck)
        let newCards = spacedRepetition.getNewFlashcards(for: deck, limit: 5)
        cards.append(contentsOf: newCards)
        
        reviewCards = cards.shuffled()
        currentCardIndex = 0
        showAnswer = false
        cardsReviewedInSession = 0
    }
    
    private func reviewCard(quality: ReviewQuality) {
        print("🔍 Starting review card with quality: \(quality.title)")
        
        guard let card = currentCard else {
            print("❌ No current card found")
            return
        }
        
        print("🔍 Processing review for card: \(card.frontText ?? "Unknown")")
        
        spacedRepetition.reviewFlashcard(card, quality: quality)
        cardsReviewedInSession += 1
        
        print("🔍 Cards reviewed in session: \(cardsReviewedInSession)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if self.currentCardIndex < self.reviewCards.count - 1 {
                    print("🔍 Moving to next card")
                    self.currentCardIndex += 1
                    self.showAnswer = false
                } else {
                    print("🔍 Session complete - showing alert")
                    self.showCompletionAlert = true
                }
            }
        }
    }


}

struct ReviewHeaderView: View {
    let currentIndex: Int
    let totalCards: Int
    let deck: Deck
    @Environment(\.dismiss) private var dismiss
    
    var progress: Double {
        guard totalCards > 0 else { return 0 }
        return Double(currentIndex - 1) / Double(totalCards)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(deck.name ?? "Flashcard Review")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(currentIndex) of \(totalCards)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .opacity(0)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct FlashcardDisplayView: View {
    let flashcard: Flashcard
    @Binding var showAnswer: Bool
    @State private var isFlipped = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.primary.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 24) {
                        HStack {
                            Text(showAnswer ? "Answer" : "Question")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            Spacer()
                            
                            Image(systemName: showAnswer ? "lightbulb.fill" : "questionmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(showAnswer ? .orange : .blue)
                        }
                        
                        Spacer()
                        
                        ScrollView {
                            Text(showAnswer ? (flashcard.backText ?? "") : (flashcard.frontText ?? ""))
                                .font(.system(size: 20, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        
                        Spacer()
                        
                        if showAnswer {
                            VStack(spacing: 8) {
                                HStack(spacing: 16) {
                                    StatItem(title: "Reviews", value: "\(flashcard.reviewCount)")
                                    StatItem(title: "Streak", value: "\(flashcard.correctStreak)")
                                    StatItem(title: "Ease", value: String(format: "%.1f", flashcard.easinessFactor))
                                }
                                
                                if let nextReview = flashcard.nextReviewDate {
                                    Text("Next review: \(nextReview, style: .relative)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(32)
                }
                .frame(maxHeight: geometry.size.height * 0.6)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .onTapGesture {
                    if !showAnswer {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showAnswer = true
                            isFlipped = true
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: showAnswer) { newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped = newValue
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

struct QualityButtonsView: View {
    let onQualitySelected: (ReviewQuality) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("How well did you know this?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(ReviewQuality.allCases, id: \.rawValue) { quality in
                    QualityButton(quality: quality) {
                        onQualitySelected(quality)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial)
    }
}

struct QualityButton: View {
    let quality: ReviewQuality
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(quality.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(quality.description)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(quality.color)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ShowAnswerButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Show Answer")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Tap the card or this button to reveal the answer")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
}

struct EmptyReviewView: View {
    let deck: Deck
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("All caught up! 🎉")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("You've reviewed all due cards in \(deck.name ?? "this deck"). Great job!")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Add More Cards") {
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Finish Session") {
                    print("🔍 Finish button tapped in EmptyReviewView")
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootViewController = window.rootViewController {
                        
                        var topController = rootViewController
                        while let presentedViewController = topController.presentedViewController {
                            topController = presentedViewController
                        }
                        
                        topController.dismiss(animated: true) {
                            DispatchQueue.main.async {
                                dismiss()
                            }
                        }
                    } else {
                        dismiss()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())


            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}




struct AdvancedFlashcardReviewView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataService.shared.context
        let sampleDeck = Deck(context: context)
        sampleDeck.name = "Sample Deck"
        return AdvancedFlashcardReviewView(deck: sampleDeck)
    }
}
