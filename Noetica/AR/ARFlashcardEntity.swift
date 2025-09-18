//
//  ARFlashcardEntity.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import RealityKit
import UIKit
import CoreData

class ARFlashcardEntity: Entity, HasModel, HasCollision {
    var flashcard: Flashcard?
    var isShowingFront = true
    
    required init() {
        self.flashcard = nil
        super.init()
    }
    
    convenience init(flashcard: Flashcard) {
        self.init()
        self.flashcard = flashcard
        setupFlashcard()
    }
    
    private func setupFlashcard() {
        guard let flashcard = flashcard else { return }
        
        let mesh = MeshResource.generatePlane(width: 0.2, depth: 0.15)
        
        let material = createTextMaterial(text: flashcard.frontText ?? "No Text", isfront: true)
        
        self.model = ModelComponent(mesh: mesh, materials: [material])
        self.collision = CollisionComponent(shapes: [.generateBox(width: 0.2, height: 0.02, depth: 0.15)])
        
        self.generateCollisionShapes(recursive: true)
    }
    
    func flipCard() {
        guard let flashcard = flashcard else { return }
        
        isShowingFront.toggle()
        
       
        let flipTransform = Transform(
            scale: SIMD3<Float>(1, 1, 1),
            rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]),
            translation: self.transform.translation
        )
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let text = self.isShowingFront ?
                (flashcard.frontText ?? "No Text") :
                (flashcard.backText ?? "No Answer")
            let material = self.createTextMaterial(text: text, isfront: self.isShowingFront)
            self.model?.materials = [material]
        }
        
        
        let rotationAnimation = FromToByAnimation<Transform>(
            from: self.transform,
            to: flipTransform,
            duration: 0.3,
            timing: .easeInOut,
            bindTarget: .transform
        )
        
        if let animationResource = try? AnimationResource.generate(with: rotationAnimation) {
            self.playAnimation(animationResource)
        }
    }
    
    private func createTextMaterial(text: String, isfront: Bool) -> SimpleMaterial {
        let textImage = generateTextImage(text: text, isfront: isfront)
        
        if let cgImage = textImage.cgImage {
            do {
                let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
                var material = SimpleMaterial()
                material.color = .init(texture: .init(texture))
                return material
            } catch {
                print("Failed to create texture: \(error)")
            }
        }
        
        
        return SimpleMaterial(color: isfront ? .systemBlue : .systemGreen, isMetallic: false)
    }
    
   
    private func generateTextImage(text: String, isfront: Bool) -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let backgroundColor = isfront ? UIColor.systemBlue : UIColor.systemGreen
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
      
        backgroundColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
       
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.lineBreakMode = .byWordWrapping
                return style
            }()
        ]
        
        
        let textRect = CGRect(x: 20, y: 40, width: size.width - 40, height: size.height - 80)
        
      
        text.draw(in: textRect, withAttributes: textAttributes)
        
        
        let indicator = isfront ? "QUESTION" : "ANSWER"
        let indicatorAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        indicator.draw(at: CGPoint(x: 20, y: 20), withAttributes: indicatorAttributes)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
