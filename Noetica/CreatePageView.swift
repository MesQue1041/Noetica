//
//  CreatePageView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI
import CoreData

enum CreateMode: String, CaseIterable {
    case note = "Note"
    case flashcard = "Flashcard"
}

struct CreatePageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedMode: CreateMode = .note
    
    @State private var title: String = ""
    @State private var bodyText: String = ""
    
    @State private var flashcardFront: String = ""
    @State private var flashcardBack: String = ""
    
    @State private var noteSubject: String = ""


    @State private var isSpeaking = false

    var editingNote: Note? = nil
    var editingFlashcard: Flashcard? = nil


    var body: some View {
        VStack(spacing: 0) {
            Text("Untitled")
                .font(.largeTitle)
                .bold()
                .padding(.top, 32)

            Picker("", selection: $selectedMode) {
                ForEach(CreateMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 40)
            .padding(.top, 12)

            if selectedMode == .note {
                TextField("Title", text: $title)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .font(.title3)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                TextField("Subject", text: $noteSubject)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .font(.body)
                    .padding(.horizontal, 32)

                ZStack(alignment: .topLeading) {
                    if bodyText.isEmpty {
                        Text("Start writing here ...")
                            .foregroundColor(Color(.systemGray3))
                            .padding(.top, 8)
                            .padding(.leading, 8)
                    }
                    TextEditor(text: $bodyText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(height: 180)
                        .font(.body)
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
            }
else {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Front (Question)", text: $flashcardFront)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .font(.title3)

                    TextField("Back (Answer)", text: $flashcardBack)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .font(.title3)
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
            }

            HStack(spacing: 16) {
                FormatButton(system: "bold", label: "B")
                FormatButton(system: "italic", label: "I")
                FormatButton(system: "list.bullet", label: "")
                FormatButton(system: "link", label: "")
                FormatButton(system: "photo", label: "")
                Spacer()
                Button(action: {
                    isSpeaking.toggle()
                    // voice thingy will be here i guess
                }) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(isSpeaking ? Color.blue.opacity(0.7) : Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
            .background(Color(.systemBackground))
            .animation(.easeIn, value: isSpeaking)

            Button(action: saveContent) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(title.isEmpty && selectedMode == .note ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
            }
            .disabled(title.isEmpty && selectedMode == .note)

            Spacer()
        }
        .background(Color(.systemBackground))
        .onAppear {
            if let note = editingNote {
                selectedMode = .note
                title = note.title ?? ""
                bodyText = note.body ?? ""
            }
            if let flashcard = editingFlashcard {
                selectedMode = .flashcard
                title = ""
                flashcardFront = flashcard.frontText ?? ""
                flashcardBack = flashcard.backText ?? ""
            }
        }
    }

    private func saveContent() {
        switch selectedMode {
        case .note:
            let note = editingNote ?? Note(context: viewContext)
            note.title = title
            note.body = bodyText
            note.dateCreated = note.dateCreated ?? Date()
            note.dateModified = Date()

            note.subject = noteSubject.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Failed to save note: \(error)")
            }

        case .flashcard:
            let card = editingFlashcard ?? Flashcard(context: viewContext)
            card.frontText = flashcardFront
            card.backText = flashcardBack
            card.dateCreated = card.dateCreated ?? Date()
            card.dateModified = Date()

            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Failed to save flashcard: \(error)")
            }
        }
    }
}

struct FormatButton: View {
    var system: String
    var label: String = ""
    var body: some View {
        Button(action: {}) {
            if label.isEmpty {
                Image(systemName: system)
                    .font(.title3)
                    .foregroundColor(.blue)
            } else {
                Text(label)
                    .bold()
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 36, height: 36)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CreatePageView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePageView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
