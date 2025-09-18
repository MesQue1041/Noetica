//
//  VoiceRecordingView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-18.
//

import SwiftUI

struct VoiceRecordingView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @Binding var recognizedText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                if speechRecognizer.isRecording {
                    VStack(spacing: 16) {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .opacity(speechRecognizer.isRecording ? 1.0 : 0.3)
                                .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: speechRecognizer.isRecording)
                            
                            Text("Recording...")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        Text("Speak now...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("Voice to Text")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tap the microphone to start recording your voice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if !speechRecognizer.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transcribed Text")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            Text(speechRecognizer.transcript)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .frame(maxHeight: 200)
                        
                        Button("Use This Text") {
                            recognizedText = speechRecognizer.transcript
                            isPresented = false
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                
                if !speechRecognizer.errorMessage.isEmpty {
                    Text(speechRecognizer.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
                
                Button(action: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    } else {
                        speechRecognizer.startRecording()
                    }
                }) {
                    Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
                        .scaleEffect(speechRecognizer.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: speechRecognizer.isRecording)
                }
                .disabled(!speechRecognizer.isAuthorized)
                
                Text(speechRecognizer.isRecording ? "Tap to stop recording" : "Tap to start recording")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        speechRecognizer.stopRecording()
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
                
                if !speechRecognizer.transcript.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            speechRecognizer.clearTranscript()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }
}

#Preview {
    VoiceRecordingView(recognizedText: .constant(""), isPresented: .constant(true))
}
