//
//  OCRTextCaptureView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-17.
//

import SwiftUI

struct OCRTextCaptureView: View {
    @StateObject private var ocrService = OCRService()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @Binding var extractedText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let image = selectedImage {
                    VStack(spacing: 16) {
                        Text("Captured Image")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        
                        if ocrService.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Extracting text...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        
                        if !ocrService.extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Extracted Text")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ScrollView {
                                    Text(ocrService.extractedText)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                .frame(maxHeight: 200)
                                
                                Button("Use This Text") {
                                    extractedText = ocrService.extractedText
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
                        
                        if !ocrService.errorMessage.isEmpty {
                            Text(ocrService.errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                } else {
                    VStack(spacing: 32) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("OCR Text Capture")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Take a photo or select from library to extract text")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                sourceType = .camera
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18))
                                    Text("Take Photo")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                sourceType = .photoLibrary
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 18))
                                    Text("Choose from Library")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("OCR Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
                
                if selectedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Retake") {
                            selectedImage = nil
                            ocrService.extractedText = ""
                            ocrService.errorMessage = ""
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            PhotoCaptureView(
                selectedImage: $selectedImage,
                isPresented: $showingCamera,
                sourceType: .camera
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoCaptureView(
                selectedImage: $selectedImage,
                isPresented: $showingImagePicker,
                sourceType: .photoLibrary
            )
        }
        .onChange(of: selectedImage) { image in
            guard let image = image else { return }
            ocrService.extractText(from: image) { text, error in
            }
        }
    }
}

#Preview {
    OCRTextCaptureView(extractedText: .constant(""), isPresented: .constant(true))
}
