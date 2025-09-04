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
    @Environment(\.dismiss) private var dismiss

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
        NavigationView {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(CreateMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                ScrollView {
                    VStack(spacing: 20) {
                        if selectedMode == .note {
                            Group {
                                StyledTextField("Title", text: $title, font: .title3)
                                StyledTextField("Subject", text: $noteSubject, font: .body)

                                ZStack(alignment: .topLeading) {
                                    if bodyText.isEmpty {
                                        Text("Start writing here …")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.top, 10)
                                    }
                                    TextEditor(text: $bodyText)
                                        .frame(minHeight: 180)
                                        .padding(8)
                                }
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        } else {
                            Group {
                                StyledTextField("Front (Question)", text: $flashcardFront, font: .title3)
                                StyledTextField("Back (Answer)", text: $flashcardBack, font: .title3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }

                HStack(spacing: 14) {
                    ForEach(formatButtons, id: \.systemName) { btn in
                        FormatButton(system: btn.systemName)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            isSpeaking.toggle()
                        }
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(isSpeaking ? Color.red : Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: isSpeaking ? 6 : 0)
                            .scaleEffect(isSpeaking ? 1.1 : 1.0)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground).shadow(radius: 1))

                Button(action: saveContent) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((title.isEmpty && selectedMode == .note) ? Color.gray.opacity(0.4) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(title.isEmpty && selectedMode == .note)

                Spacer(minLength: 12)
            }
            .navigationTitle(selectedMode == .note ? "New Note" : "New Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveContent() }
                        .disabled(title.isEmpty && selectedMode == .note)
                }
            }
            .onAppear {
                if let note = editingNote {
                    selectedMode = .note
                    title = note.title ?? ""
                    bodyText = note.body ?? ""
                    noteSubject = note.subject ?? ""
                }
                if let flashcard = editingFlashcard {
                    selectedMode = .flashcard
                    flashcardFront = flashcard.frontText ?? ""
                    flashcardBack = flashcard.backText ?? ""
                }
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
                dismiss()
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
                dismiss()
            } catch {
                print("Failed to save flashcard: \(error)")
            }
        }
    }

    private var formatButtons: [FormatButtonModel] {
        [
            .init(systemName: "bold"),
            .init(systemName: "italic"),
            .init(systemName: "list.bullet"),
            .init(systemName: "link"),
            .init(systemName: "photo")
        ]
    }
}

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var font: Font = .body

    init(_ placeholder: String, text: Binding<String>, font: Font = .body) {
        self.placeholder = placeholder
        self._text = text
        self.font = font
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .font(font)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}

struct FormatButtonModel {
    let systemName: String
}

struct FormatButton: View {
    var system: String

    var body: some View {
        Button(action: {}) {
            Image(systemName: system)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct CreatePageView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePageView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
