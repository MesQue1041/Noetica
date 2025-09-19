//
//  FlashcardReviewView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//


import SwiftUI

struct FlashcardReviewView: View {
    @State private var currentIndex = 0
    @State private var showAnswer = false
    let flashcards: [Flashcard]
    
    var body: some View {
        VStack(spacing: 24) {
            if flashcards.isEmpty {
                Text("No flashcards to review")
                    .font(.title)
                    .foregroundColor(.gray)
                    .accessibilityLabel("No flashcards available")
                    .accessibilityHint("Add flashcards to start reviewing")
            } else {
                Text("Flashcard \(currentIndex + 1) of \(flashcards.count)")
                    .font(.headline)
                    .foregroundColor(Color.purple)
                    .padding(.top)
                    .accessibilityLabel("Progress: card \(currentIndex + 1) of \(flashcards.count)")
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(radius: 8)
                        .frame(height: 320)
                        .rotation3DEffect(.degrees(showAnswer ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    
                    VStack {
                        Text(showAnswer ? (flashcards[currentIndex].backText ?? "") : (flashcards[currentIndex].frontText ?? ""))
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    .frame(height: 320)
                    .rotation3DEffect(.degrees(showAnswer ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                }
                .padding()
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        showAnswer.toggle()
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(showAnswer ? "Answer: \(flashcards[currentIndex].backText ?? "")" : "Question: \(flashcards[currentIndex].frontText ?? "")")
                .accessibilityHint(showAnswer ? "Tap to show question again" : "Tap to reveal answer")
                .accessibilityAction(named: showAnswer ? "Show question" : "Show answer") {
                    withAnimation(.easeInOut) {
                        showAnswer.toggle()
                    }
                }
                
                Spacer()
                
                if showAnswer {
                    HStack(spacing: 40) {
                        Button("Easy") {
                            markDifficulty(easy: true)
                        }
                        .buttonStyle(ReviewButtonStyle(color: .green))
                        .accessibilityLabel("Mark as easy")
                        .accessibilityHint("This flashcard was easy to remember")
                        
                        Button("Hard") {
                            markDifficulty(easy: false)
                        }
                        .buttonStyle(ReviewButtonStyle(color: .red))
                        .accessibilityLabel("Mark as hard")
                        .accessibilityHint("This flashcard was difficult to remember")
                    }
                    .padding(.bottom)
                    .padding()
                }
            }
        }
    }
    
    private func markDifficulty(easy: Bool) {
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
            showAnswer = false
        }
    }
}


struct ReviewButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 110, height: 46)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FlashcardReviewView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleCard = Flashcard(context: context)
        sampleCard.frontText = "Sample Question"
        sampleCard.backText = "Sample Answer"
        return FlashcardReviewView(flashcards: [sampleCard])
            .environment(\.managedObjectContext, context)
    }
}
