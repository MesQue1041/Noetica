//
//  MLTextClassifier.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import Foundation
import CoreML
import NaturalLanguage

class MLTextClassifier: ObservableObject {
    static let shared = MLTextClassifier()
    
    private var model: NLModel?
    @Published var isReady = false
    @Published var lastPrediction = ""
    
    private init() {
        setupModel()
    }
    
    private func setupModel() {
        guard let modelURL = Bundle.main.url(forResource: "SubjectClassifier", withExtension: "mlmodelc") else {
            print("Could not find model file")
            return
        }
        
        do {
            model = try NLModel(contentsOf: modelURL)
            isReady = true
            print("ML Text Classifier loaded successfully")
        } catch {
            print("Error loading model: \(error)")
        }
    }
        
    func classifyText(_ text: String) -> String {
        guard let model = model, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "General"
        }
        
        let prediction = model.predictedLabel(for: text) ?? "General"
        lastPrediction = prediction
        
        print("Note Classified: '\(text.prefix(50))...' → \(prediction)")
        return prediction
    }
    
    func classifyWithConfidence(_ text: String) -> (label: String, confidence: Double) {
        guard let model = model, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ("General", 0.0)
        }
        
        let prediction = model.predictedLabel(for: text) ?? "General"
        
        let labelHypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 5)
        let topConfidence = labelHypotheses[prediction] ?? 0.0
        
        return (prediction, topConfidence)
    }

    
    func classifyNote(title: String, body: String) -> String {
        let combinedText = "\(title) \(body)"
        return classifyText(combinedText)
    }
}
