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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if flashcards.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 64, weight: .ultraLight))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No flashcards to review")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Add some flashcards to get started")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("No flashcards available")
                    .accessibilityHint("Add flashcards to start reviewing")
                } else {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Flashcard Review")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("\(currentIndex + 1) of \(flashcards.count)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .stroke(.quaternary, lineWidth: 3)
                                    .frame(width: 44, height: 44)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(currentIndex + 1) / CGFloat(flashcards.count))
                                    .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .frame(width: 44, height: 44)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(Int((Double(currentIndex + 1) / Double(flashcards.count)) * 100))%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        GeometryReader { progressGeometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.quaternary)
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.blue)
                                    .frame(width: progressGeometry.size.width * CGFloat(currentIndex + 1) / CGFloat(flashcards.count), height: 4)
                                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 32) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.primary.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                            
                            VStack(spacing: 24) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: showAnswer ? "lightbulb.fill" : "questionmark.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(showAnswer ? .orange : .blue)
                                        
                                        Text(showAnswer ? "ANSWER" : "QUESTION")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(showAnswer ? .orange : .blue)
                                            .tracking(1.2)
                                    }
                                    
                                    Spacer()
                                    
                                    if !showAnswer {
                                        HStack(spacing: 4) {
                                            Image(systemName: "hand.tap.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                            Text("Tap to reveal")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                ScrollView {
                                    Text(showAnswer ? (flashcards[currentIndex].backText ?? "") : (flashcards[currentIndex].frontText ?? ""))
                                        .font(.system(size: 22, weight: .medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.primary)
                                        .lineSpacing(6)
                                        .padding(.horizontal, 8)
                                }
                                
                                Spacer()
                            }
                            .padding(28)
                        }
                        .frame(height: min(geometry.size.height * 0.5, 400))
                        .padding(.horizontal, 24)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAnswer.toggle()
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(showAnswer ? "Answer: \(flashcards[currentIndex].backText ?? "")" : "Question: \(flashcards[currentIndex].frontText ?? "")")
                        .accessibilityHint(showAnswer ? "Tap to show question again" : "Tap to reveal answer")
                        .accessibilityAction(named: showAnswer ? "Show question" : "Show answer") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAnswer.toggle()
                            }
                        }
                        
                        if showAnswer {
                            VStack(spacing: 16) {
                                Text("How well did you know this?")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 16) {
                                    Button(action: { markDifficulty(easy: false) }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.red)
                                            
                                            Text("Hard")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.red)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(.red.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.red.opacity(0.2), lineWidth: 1)
                                        )
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .accessibilityLabel("Mark as hard")
                                    .accessibilityHint("This flashcard was difficult to remember")
                                    .frame(minWidth: 44, minHeight: 44)
                                    
                                    Button(action: { markDifficulty(easy: true) }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.green)
                                            
                                            Text("Easy")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.green)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(.green.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.green.opacity(0.2), lineWidth: 1)
                                        )
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .accessibilityLabel("Mark as easy")
                                    .accessibilityHint("This flashcard was easy to remember")
                                    .frame(minWidth: 44, minHeight: 44)
                                }
                                .padding(.horizontal, 24)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
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
