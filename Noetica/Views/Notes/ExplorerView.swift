//
//  ExplorerView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-11.
//

import SwiftUI
import CoreData

struct NotesExplorerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var statsService: StatsService
    
    @State private var selectedMode: ExplorerMode = .notes
    @State private var searchText = ""
    @State private var showingCreateSubject = false
    @State private var showingCreateDeck = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateModified, ascending: false)],
        animation: .default
    ) private var notes: FetchedResults<Note>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.name, ascending: true)],
        animation: .default
    ) private var decks: FetchedResults<Deck>
    
    var subjectsFromData: [ExplorerSubject] {
        let subjectStats = statsService.getSubjectStats()
        return subjectStats.map { stat in
            ExplorerSubject(
                name: stat.subject,
                color: stat.color,
                noteCount: stat.noteCount,
                imageName: getSubjectIcon(for: stat.subject)
            )
        }
    }
    
    var decksFromData: [ExplorerDeck] {
        return decks.map { deck in
            let flashcardCount = (deck.flashcards as? Set<Flashcard>)?.count ?? 0
            return ExplorerDeck(
                name: deck.name ?? "Untitled Deck",
                color: Color.randomStudyColor(),
                cardCount: flashcardCount,
                masteryLevel: deck.mastery
            )
        }
    }
    
    var filteredSubjects: [ExplorerSubject] {
        if searchText.isEmpty {
            return subjectsFromData
        }
        return subjectsFromData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredDecks: [ExplorerDeck] {
        if searchText.isEmpty {
            return decksFromData
        }
        return decksFromData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ExplorerHeaderSection(
                        selectedMode: $selectedMode,
                        searchText: $searchText,
                        showingCreateSubject: $showingCreateSubject,
                        showingCreateDeck: $showingCreateDeck
                    )
                    
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 16
                        ) {
                            if selectedMode == .notes {
                                if filteredSubjects.isEmpty {
                                    EmptyStateView(
                                        icon: "doc.text",
                                        title: "No Notes Yet",
                                        subtitle: "Create your first note to get started",
                                        buttonTitle: "Create Note",
                                        action: { showingCreateSubject = true }
                                    )
                                } else {
                                    ForEach(filteredSubjects) { subject in
                                        ExplorerSubjectTile(subject: subject)
                                    }
                                }
                            } else {
                                if filteredDecks.isEmpty {
                                    EmptyStateView(
                                        icon: "rectangle.stack",
                                        title: "No Decks Yet",
                                        subtitle: "Create your first flashcard deck",
                                        buttonTitle: "Create Deck",
                                        action: { showingCreateDeck = true }
                                    )
                                } else {
                                    ForEach(filteredDecks) { deck in
                                        ExplorerDeckTile(deck: deck)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateSubject) {
            CreatePageView()
        }
        .sheet(isPresented: $showingCreateDeck) {
            DeckCreationView()
        }
        .onAppear {
            statsService.updateStats()
        }
    }
    
    private func getSubjectIcon(for subject: String) -> String {
        let lowercased = subject.lowercased()
        switch lowercased {
        case let s where s.contains("math"): return "function"
        case let s where s.contains("phys"): return "atom"
        case let s where s.contains("chem"): return "testtube.2"
        case let s where s.contains("bio"): return "leaf"
        case let s where s.contains("hist"): return "book.closed"
        case let s where s.contains("lit") || s.contains("english"): return "text.book.closed"
        case let s where s.contains("art"): return "paintpalette"
        case let s where s.contains("music"): return "music.note"
        case let s where s.contains("comp") || s.contains("program"): return "laptopcomputer"
        default: return "book.fill"
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct ExplorerHeaderSection: View {
    @Binding var selectedMode: ExplorerMode
    @Binding var searchText: String
    @Binding var showingCreateSubject: Bool
    @Binding var showingCreateDeck: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Explorer")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Organize your learning")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    if selectedMode == .notes {
                        showingCreateSubject = true
                    } else {
                        showingCreateDeck = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            HStack(spacing: 0) {
                ForEach(ExplorerMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(mode.title)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(selectedMode == mode ? .white : .secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(selectedMode == mode ?
                                      LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing) :
                                      LinearGradient(gradient: Gradient(colors: [Color.clear]), startPoint: .leading, endPoint: .trailing)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search \(selectedMode.title.lowercased())", text: $searchText)
                    .font(.system(size: 16))
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

struct ExplorerSubjectTile: View {
    let subject: ExplorerSubject
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            subject.color.opacity(0.3),
                                            subject.color.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: subject.imageName)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(subject.color)
                        }
                        
                        VStack(spacing: 4) {
                            Text(subject.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text("\(subject.noteCount) notes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(subject.color)
                        .frame(height: 3)
                }
            }
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(subject.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: subject.color.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ExplorerDeckTile: View {
    let deck: ExplorerDeck
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: DeckDetailView(deck: deck)) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(deck.color.opacity(0.15), lineWidth: 6)
                                .frame(width: 64, height: 64)
                            
                            Circle()
                                .trim(from: 0, to: deck.masteryLevel)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [deck.color, deck.color.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                            
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(deck.color)
                        }
                        
                        VStack(spacing: 4) {
                            Text(deck.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text("\(deck.cardCount) cards")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("\(Int(deck.masteryLevel * 100))%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(deck.color)
                            )
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
            }
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(deck.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: deck.color.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct SubjectDetailView: View {
    let subject: ExplorerSubject
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var notes: FetchedResults<Note>
    
    init(subject: ExplorerSubject) {
        self.subject = subject
        self._notes = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateModified, ascending: false)],
            predicate: NSPredicate(format: "subject == %@", subject.name),
            animation: .default
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        
                        Text("No notes yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Create your first note in \(subject.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(notes, id: \.objectID) { note in
                        NavigationLink(destination: NoteDetailView(note: note)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.title ?? "Untitled Note")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let body = note.body, !body.isEmpty {
                                    Text(body)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                
                                HStack {
                                    Text(note.dateModified?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(subject.name)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(subject.color)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
            .navigationTitle(subject.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            offsets.map { notes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting notes: \(error)")
            }
        }
    }
}

struct NoteDetailView: View {
    let note: Note
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.title ?? "Untitled Note")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let subject = note.subject {
                    Text(subject)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text(note.body ?? "")
                    .font(.body)
                    .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct DeckDetailView: View {
    let deck: ExplorerDeck
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var actualDecks: FetchedResults<Deck>
    
    init(deck: ExplorerDeck) {
        self.deck = deck
        self._actualDecks = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Deck.name, ascending: true)],
            predicate: NSPredicate(format: "name == %@", deck.name),
            animation: .default
        )
    }
    
    var actualDeck: Deck? {
        actualDecks.first
    }
    
    var flashcards: [Flashcard] {
        guard let deck = actualDeck else { return [] }
        return (deck.flashcards as? Set<Flashcard>)?.sorted { card1, card2 in
            (card1.dateCreated ?? Date.distantPast) > (card2.dateCreated ?? Date.distantPast)
        } ?? []
    }
    
    var body: some View {
        NavigationView {
            List {
                if flashcards.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        
                        Text("No flashcards yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Create your first flashcard in \(deck.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(flashcards, id: \.objectID) { flashcard in
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Question")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(flashcard.frontText ?? "")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Answer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(flashcard.backText ?? "")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            
                            HStack {
                                Text("Created: \(flashcard.dateCreated?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if flashcard.difficultyRating > 0 {
                                    HStack(spacing: 2) {
                                        ForEach(1...Int(flashcard.difficultyRating), id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteFlashcards)
                }
            }
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func deleteFlashcards(offsets: IndexSet) {
        withAnimation {
            offsets.map { flashcards[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting flashcards: \(error)")
            }
        }
    }
}


#Preview {
    NotesExplorerView()
        .environment(\.managedObjectContext, CoreDataService.shared.context)
        .environmentObject(StatsService())
}
