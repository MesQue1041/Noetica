//
//  SpeechRecognizer.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var errorMessage = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        Task {
            await requestPermissions()
        }
    }
    
    @MainActor
    private func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        isAuthorized = speechStatus == .authorized && audioStatus
        
        if !isAuthorized {
            errorMessage = "Speech recognition or microphone access denied"
        }
    }
    
    func startRecording() {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        guard isAuthorized else {
            errorMessage = "Not authorized for speech recognition"
            return
        }
        
        
        stopRecording()
        
      
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
            return
        }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        request.shouldReportPartialResults = true
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            errorMessage = "Unable to create audio engine"
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
            return
        }
        
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self?.stopRecording()
                }
            }
        }
        
        isRecording = true
        errorMessage = ""
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        request?.endAudio()
        request = nil
        
        task?.cancel()
        task = nil
        
        isRecording = false
    }
    
    func clearTranscript() {
        transcript = ""
        errorMessage = ""
    }
}
