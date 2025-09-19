//
//  ARFlashcardView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import SwiftUI
import RealityKit
import ARKit

struct ARFlashcardView: UIViewRepresentable {
    let flashcards: [Flashcard]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        arView.session.delegate = context.coordinator
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        context.coordinator.setupGestures(for: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.flashcards = flashcards
        context.coordinator.currentIndex = currentIndex
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARFlashcardView
        var flashcards: [Flashcard] = []
        var currentIndex = 0
        var currentFlashcardEntity: ARFlashcardEntity?
        var arView: ARView?
        var planeAnchorEntity: AnchorEntity?
        
        init(_ parent: ARFlashcardView) {
            self.parent = parent
            super.init()
        }
        
        func setupGestures(for arView: ARView) {
            self.arView = arView
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tapGesture)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
            swipeLeft.direction = .left
            arView.addGestureRecognizer(swipeLeft)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
            swipeRight.direction = .right
            arView.addGestureRecognizer(swipeRight)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            if let entity = arView.entity(at: location) as? ARFlashcardEntity {
                entity.flipCard()
            }
        }
        
        @objc func handleSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
            nextCard()
        }
        
        @objc func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
            previousCard()
        }
        
        func nextCard() {
            guard !flashcards.isEmpty else { return }
            currentIndex = (currentIndex + 1) % flashcards.count
            parent.currentIndex = currentIndex
            updateFlashcard()
        }
        
        func previousCard() {
            guard !flashcards.isEmpty else { return }
            currentIndex = currentIndex > 0 ? currentIndex - 1 : flashcards.count - 1
            parent.currentIndex = currentIndex
            updateFlashcard()
        }
        
        func updateFlashcard() {
            guard !flashcards.isEmpty,
                  currentIndex < flashcards.count,
                  let planeAnchorEntity = planeAnchorEntity else { return }
            
            currentFlashcardEntity?.removeFromParent()
            
            let newFlashcard = flashcards[currentIndex]
            currentFlashcardEntity = ARFlashcardEntity(flashcard: newFlashcard)
            
            if let flashcardEntity = currentFlashcardEntity {
                planeAnchorEntity.addChild(flashcardEntity)
            }
        }
        
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let arView = arView else { return }
            
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    if planeAnchor.alignment == .horizontal {
                        
                        let anchorEntity = AnchorEntity(.plane(.horizontal,
                                                              classification: .any,
                                                              minimumBounds: [0.2, 0.2]))
                        
                        arView.scene.addAnchor(anchorEntity)
                        self.planeAnchorEntity = anchorEntity
                        
                        if !flashcards.isEmpty && currentFlashcardEntity == nil {
                            currentFlashcardEntity = ARFlashcardEntity(flashcard: flashcards[currentIndex])
                            if let flashcardEntity = currentFlashcardEntity {
                                anchorEntity.addChild(flashcardEntity)
                            }
                        }
                        
                        break
                    }
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        }
    }
}
