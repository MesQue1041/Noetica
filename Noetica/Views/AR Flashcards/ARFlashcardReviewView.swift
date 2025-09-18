//
//  ARFlashcardReviewView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import SwiftUI
import ARKit
import RealityKit

struct ARFlashcardReviewView: View {
    let flashcards: [Flashcard]
    @Binding var isPresented: Bool
    @State private var currentCardIndex = 0
    @State private var showAnswer = false
    
    var currentCard: Flashcard? {
        guard currentCardIndex < flashcards.count else { return nil }
        return flashcards[currentCardIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if !flashcards.isEmpty {
                    ARViewContainer(
                        flashcard: currentCard,
                        showAnswer: $showAnswer,
                        onNext: nextCard,
                        onPrevious: previousCard
                    )
                    .ignoresSafeArea()
                    
                    VStack {
                        // Top Controls
                        HStack {
                            Button("Close") {
                                isPresented = false
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            
                            Spacer()
                            
                            Text("\(currentCardIndex + 1) / \(flashcards.count)")
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom Controls
                        if !showAnswer {
                            Button("Show Answer") {
                                withAnimation {
                                    showAnswer = true
                                }
                            }
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(25)
                            .padding(.bottom, 50)
                        } else {
                            HStack(spacing: 20) {
                                Button("Previous") {
                                    previousCard()
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                
                                Button("Next") {
                                    nextCard()
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                            }
                            .padding(.bottom, 50)
                        }
                    }
                } else {
                    VStack {
                        Text("No flashcards available")
                            .font(.title)
                        Button("Close") {
                            isPresented = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func nextCard() {
        withAnimation {
            if currentCardIndex < flashcards.count - 1 {
                currentCardIndex += 1
                showAnswer = false
            }
        }
    }
    
    private func previousCard() {
        withAnimation {
            if currentCardIndex > 0 {
                currentCardIndex -= 1
                showAnswer = false
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let flashcard: Flashcard?
    @Binding var showAnswer: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Clear existing content
        uiView.scene.anchors.removeAll()
        
        guard let flashcard = flashcard else { return }
        
        // Create the flashcard entity
        let cardEntity = createFlashcardEntity(
            frontText: flashcard.frontText ?? "Question",
            backText: flashcard.backText ?? "Answer",
            showAnswer: showAnswer
        )
        
        // Create anchor at origin
        let anchor = AnchorEntity(world: [0, 0, -1])
        anchor.addChild(cardEntity)
        uiView.scene.addAnchor(anchor)
    }
    
    private func createFlashcardEntity(frontText: String, backText: String, showAnswer: Bool) -> Entity {
        // Create a simple box as flashcard
        let cardMesh = MeshResource.generateBox(width: 0.3, height: 0.2, depth: 0.01)
        
        // Create material - Using UnlitMaterial for better performance
        let material = UnlitMaterial(color: showAnswer ? .green : .blue)
        
        let cardEntity = ModelEntity(mesh: cardMesh, materials: [material])
        
        // Add collision for tap detection
        cardEntity.generateCollisionShapes(recursive: true)
        
        return cardEntity
    }
    
    // Preview
    struct ARFlashcardReviewView_Previews: PreviewProvider {
        static var previews: some View {
            ARFlashcardReviewView(
                flashcards: [],
                isPresented: .constant(true)
            )
        }
    }
}
