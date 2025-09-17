//
//  OCRService.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-17.
//

import UIKit
import Vision
import VisionKit

class OCRService: ObservableObject {
    @Published var extractedText = ""
    @Published var isProcessing = false
    @Published var errorMessage = ""
    
    func extractText(from image: UIImage, completion: @escaping (String?, Error?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil, OCRError.invalidImage)
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(nil, error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(nil, OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                let extractedText = recognizedStrings.joined(separator: "\n")
                self?.extractedText = extractedText
                completion(extractedText, nil)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                completion(nil, error)
            }
        }
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}
