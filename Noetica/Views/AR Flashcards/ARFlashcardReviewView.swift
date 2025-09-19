//
//  ARFlashcardReviewView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import SwiftUI
import ARKit
import RealityKit
import CoreData

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
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        // Add tap gesture to flip card
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            
            let location = gesture.location(in: arView)
            
            if let entity = arView.entity(at: location) as? ARFlashcardEntity {
                entity.flipCard()
                DispatchQueue.main.async {
                    self.parent.showAnswer.toggle()
                }
            }
        }
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.scene.anchors.removeAll()
        
        guard let flashcard = flashcard else { return }
        
        let cardEntity = createFlashcardEntity(
            frontText: flashcard.frontText ?? "Question",
            backText: flashcard.backText ?? "Answer",
            showAnswer: showAnswer
        )
        
        let anchor = AnchorEntity(world: [0, 0, -1])
        anchor.addChild(cardEntity)
        uiView.scene.addAnchor(anchor)
    }
    
    private func createFlashcardEntity(frontText: String, backText: String, showAnswer: Bool) -> Entity {
        // Create a temporary flashcard object for the AR entity
        let tempFlashcard = TempFlashcard(frontText: frontText, backText: backText)
        
        // Create the AR flashcard entity with proper text rendering
        let arEntity = ARFlashcardEntity(flashcard: tempFlashcard)
        
        // Set the correct side based on showAnswer
        if showAnswer != arEntity.isShowingFront {
            arEntity.flipCard()
        }
        
        return arEntity
    }
}

// Temporary flashcard class to work with ARFlashcardEntity
class TempFlashcard: Flashcard {
    private let _frontText: String = ""
    private let _backText: String = ""
    
    convenience init(frontText: String, backText: String) {
        self.init(entity: NSEntityDescription(), insertInto: nil)
        self.setValue(frontText, forKey: "frontText")
        self.setValue(backText, forKey: "backText")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    struct ARFlashcardReviewView_Previews: PreviewProvider {
        static var previews: some View {
            ARFlashcardReviewView(
                flashcards: [],
                isPresented: .constant(true)
            )
        }
    }
}
