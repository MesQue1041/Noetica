//
//  CreatePageView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI
import CoreData

struct CreatePageView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var statsService: StatsService
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var selectedMode: CreateMode = .note
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var flashcardFront: String = ""
    @State private var flashcardBack: String = ""
    @State private var noteSubject: String = ""
    @State private var isSpeaking = false
    @State private var showingSaveAnimation = false
    @State private var selectedDeckForFlashcard: String = "General Flashcards"
    @State private var showingDeckPicker = false
    @State private var availableDeckNames: [String] = ["General Flashcards"]
    @State private var showingOCRCapture = false
    @State private var showingVoiceRecording = false



    var editingNote: Note? = nil
    var editingFlashcard: Flashcard? = nil
    
    enum Field {
        case title, subject, body, front, back
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create Content")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Express your ideas and knowledge")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(CreateMode.allCases, id: \.self) { mode in
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMode = mode
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(mode.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(selectedMode == mode ? .white : mode.color)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedMode == mode ? mode.color : mode.color.opacity(0.1))
                                )
                                .shadow(color: selectedMode == mode ? mode.color.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
                                .scaleEffect(selectedMode == mode ? 1.02 : 1.0)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color(.systemGroupedBackground))
                
                ScrollView {
                    VStack(spacing: 24) {
                        if selectedMode == .note {
                            VStack(spacing: 20) {
                                ModernInputField(
                                    title: "Title",
                                    placeholder: "Enter note title...",
                                    text: $title,
                                    icon: "doc.text.fill",
                                    iconColor: .blue,
                                    focusedField: $focusedField,
                                    fieldType: .title
                                )
                                
                                ModernInputField(
                                    title: "Subject",
                                    placeholder: "Enter subject...",
                                    text: $noteSubject,
                                    icon: "book.fill",
                                    iconColor: .green,
                                    focusedField: $focusedField,
                                    fieldType: .subject
                                )
                                
                                ModernTextEditor(
                                    title: "Content",
                                    placeholder: "Start writing your note here...",
                                    text: $bodyText,
                                    icon: "text.alignleft",
                                    iconColor: .purple,
                                    focusedField: $focusedField,
                                    fieldType: .body
                                )
                            }
                        } else {
                            VStack(spacing: 20) {
                                ModernTextEditor(
                                    title: "Front (Question)",
                                    placeholder: "Enter your question here...",
                                    text: $flashcardFront,
                                    icon: "questionmark.circle.fill",
                                    iconColor: .blue,
                                    focusedField: $focusedField,
                                    fieldType: .front,
                                    minHeight: 120
                                )
                                
                                ModernTextEditor(
                                    title: "Back (Answer)",
                                    placeholder: "Enter your answer here...",
                                    text: $flashcardBack,
                                    icon: "lightbulb.fill",
                                    iconColor: .orange,
                                    focusedField: $focusedField,
                                    fieldType: .back,
                                    minHeight: 120
                                )
                                
                                SimpleDeckPickerField(
                                    selectedDeck: $selectedDeckForFlashcard,
                                    availableDeckNames: availableDeckNames,
                                    showingDeckPicker: $showingDeckPicker
                                )
                            }
                        }
                        
                        ModernFormattingToolbar(
                            isSpeaking: $isSpeaking,
                            showingOCRCapture: $showingOCRCapture,
                            showingVoiceRecording: $showingVoiceRecording  
                        )
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
                
                VStack(spacing: 0) {
                    Divider()
                    
                    ModernSaveButton(
                        selectedMode: selectedMode,
                        isValid: isContentValid,
                        showingSaveAnimation: $showingSaveAnimation,
                        action: saveContent
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadExistingContent()
            loadAvailableDecks()
        }
        .sheet(isPresented: $showingOCRCapture) {
            OCRTextCaptureView(
                extractedText: selectedMode == .note ? $bodyText : $flashcardFront,
                isPresented: $showingOCRCapture
            )
        }
        .sheet(isPresented: $showingVoiceRecording) {
              VoiceRecordingView(
                  recognizedText: selectedMode == .note ? $bodyText : $flashcardFront,
                  isPresented: $showingVoiceRecording
              )
          }
      

    }
    
    private var isContentValid: Bool {
        switch selectedMode {
        case .note:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .flashcard:
            return !flashcardFront.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !flashcardBack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func loadExistingContent() {
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
    
    private func loadAvailableDecks() {
        let request: NSFetchRequest<Deck> = Deck.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Deck.name, ascending: true)]
        
        do {
            let decks = try viewContext.fetch(request)
            let deckNames = decks.compactMap { $0.name }.filter { !$0.isEmpty }
            var allNames = ["General Flashcards"]
            allNames.append(contentsOf: deckNames)
            availableDeckNames = Array(Set(allNames)).sorted()
        } catch {
            availableDeckNames = ["General Flashcards"]
            print("Error loading decks: \(error)")
        }
    }

    private func saveContent() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingSaveAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSaveAnimation = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                } catch {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSaveAnimation = false
                    }
                    print("Failed to save note: \(error)")
                }
                
            case .flashcard:
                let card = editingFlashcard ?? Flashcard(context: viewContext)
                card.frontText = flashcardFront
                card.backText = flashcardBack
                card.dateCreated = card.dateCreated ?? Date()
                card.dateModified = Date()
                card.difficultyRating = 0
                
                if editingFlashcard == nil {
                    card.easinessFactor = 2.5
                    card.repetitions = 0
                    card.interval = 1
                    card.nextReviewDate = Date()
                    card.reviewCount = 0
                    card.correctStreak = 0
                }
                
                assignFlashcardToDeck(card)
                
                do {
                    try viewContext.save()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSaveAnimation = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                } catch {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSaveAnimation = false
                    }
                    print("Failed to save flashcard: \(error)")
                }

            }
        }
    }

    private func assignFlashcardToDeck(_ flashcard: Flashcard) {
        let deckRequest: NSFetchRequest<Deck> = Deck.fetchRequest()
        deckRequest.predicate = NSPredicate(format: "name == %@", selectedDeckForFlashcard)
        
        do {
            let matchingDecks = try viewContext.fetch(deckRequest)
            if let existingDeck = matchingDecks.first {
                flashcard.deck = existingDeck
            } else {
                let newDeck = Deck(context: viewContext)
                newDeck.id = UUID()
                newDeck.name = selectedDeckForFlashcard
                newDeck.subject = "General"
                newDeck.mastery = 0.0
                flashcard.deck = newDeck
            }
        } catch {
            print("Error assigning flashcard to deck: \(error)")
        }
    }
}

struct SimpleDeckPickerField: View {
    @Binding var selectedDeck: String
    let availableDeckNames: [String]
    @Binding var showingDeckPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Deck")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Button(action: {
                showingDeckPicker = true
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedDeck)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Tap to change deck")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                )
            }
            .sheet(isPresented: $showingDeckPicker) {
                SimpleDeckPickerSheet(
                    selectedDeck: $selectedDeck,
                    deckNames: availableDeckNames
                )
            }
        }
    }
}

struct SimpleDeckPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDeck: String
    let deckNames: [String]
    
    var body: some View {
        NavigationView {
            List {
                Section("Available Decks (\(deckNames.count))") {
                    ForEach(deckNames, id: \.self) { deckName in
                        Button(action: {
                            selectedDeck = deckName
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(deckName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if deckName != "General Flashcards" {
                                        Text("Custom deck")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Default deck")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if deckName == selectedDeck {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ModernInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    let iconColor: Color
    @FocusState.Binding var focusedField: CreatePageView.Field?
    let fieldType: CreatePageView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            TextField(placeholder, text: $text)
                .focused($focusedField, equals: fieldType)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == fieldType ? iconColor : Color(.systemGray5), lineWidth: focusedField == fieldType ? 2 : 1)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }
}

struct ModernTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    let iconColor: Color
    @FocusState.Binding var focusedField: CreatePageView.Field?
    let fieldType: CreatePageView.Field
    let minHeight: CGFloat
    
    init(title: String, placeholder: String, text: Binding<String>, icon: String, iconColor: Color, focusedField: FocusState<CreatePageView.Field?>.Binding, fieldType: CreatePageView.Field, minHeight: CGFloat = 200) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.iconColor = iconColor
        self._focusedField = focusedField
        self.fieldType = fieldType
        self.minHeight = minHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                TextEditor(text: $text)
                    .focused($focusedField, equals: fieldType)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(minHeight: minHeight)
                    .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == fieldType ? iconColor : Color(.systemGray5), lineWidth: focusedField == fieldType ? 2 : 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }
}

struct ModernFormattingToolbar: View {
    @Binding var isSpeaking: Bool
    @Binding var showingOCRCapture: Bool
    @Binding var showingVoiceRecording: Bool
    
    private let formatButtons: [(String, String, Color)] = [
        ("bold", "Bold", Color.blue),
        ("italic", "Italic", Color.green),
        ("list.bullet", "List", Color.orange),
        ("link", "Link", Color.purple),
        ("text.viewfinder", "OCR", Color.red)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Formatting Tools")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(formatButtons, id: \.0) { (icon, label, color) in
                    Button(action: {
                        if icon == "text.viewfinder" {
                            showingOCRCapture = true
                        }
                    }) {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(color.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingVoiceRecording = true
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.blue)
                        )
                        .shadow(
                            color: Color.blue.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 4
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}


struct ModernSaveButton: View {
    let selectedMode: CreateMode
    let isValid: Bool
    @Binding var showingSaveAnimation: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if showingSaveAnimation {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(showingSaveAnimation ? "Saving..." : "Save \(selectedMode.rawValue)")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isValid ? selectedMode.color : Color.gray)
            .cornerRadius(16)
            .shadow(color: isValid ? selectedMode.color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            .scaleEffect(showingSaveAnimation ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: showingSaveAnimation)
        }
        .disabled(!isValid || showingSaveAnimation)
    }
}

struct CreatePageView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePageView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
