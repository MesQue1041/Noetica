//
//  ExplorerView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-11.
//

import SwiftUI
import CoreData

struct NotesExplorerView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var statsService: StatsService
    
    @State private var selectedMode: ExplorerMode = .notes
    @State private var searchText = ""
    @State private var showingCreateSubject = false
    @State private var showingCreateDeck = false
    @State private var showingARReview = false

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
                id: UUID(),
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
                id: UUID(),
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
        mainContent
            .navigationBarHidden(true)
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
    
    private var mainContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                headerSection
                contentScrollView
            }
        }
    }
    
    private var headerSection: some View {
        ExplorerHeaderSection(
            selectedMode: $selectedMode,
            searchText: $searchText,
            showingCreateSubject: $showingCreateSubject,
            showingCreateDeck: $showingCreateDeck
        )
    }
    
    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                contentGrid
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 120)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var contentGrid: some View {
        if selectedMode == .notes {
            notesContent
        } else {
            decksContent
        }
    }
    
    @ViewBuilder
    private var notesContent: some View {
        if filteredSubjects.isEmpty {
            notesEmptyState
        } else {
            notesGrid
        }
    }
    
    @ViewBuilder
    private var decksContent: some View {
        if filteredDecks.isEmpty {
            decksEmptyState
        } else {
            decksGrid
        }
    }
    
    private var notesEmptyState: some View {
        ModernEmptyStateView(
            icon: "doc.text",
            title: "No Notes Yet",
            subtitle: "Create your first note to get started",
            buttonTitle: "Create Note",
            action: { showingCreateSubject = true }
        )
    }
    
    private var decksEmptyState: some View {
        ModernEmptyStateView(
            icon: "rectangle.stack",
            title: "No Decks Yet",
            subtitle: "Create your first flashcard deck",
            buttonTitle: "Create Deck",
            action: { showingCreateDeck = true }
        )
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }
    
    private var notesGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(filteredSubjects) { subject in
                ModernExplorerSubjectTile(subject: subject)
            }
        }
    }
    
    private var decksGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(filteredDecks) { deck in
                ModernExplorerDeckTile(deck: deck)
            }
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

struct ModernEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.blue.opacity(0.08))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

struct ExplorerHeaderSection: View {
    @Binding var selectedMode: ExplorerMode
    @Binding var searchText: String
    @Binding var showingCreateSubject: Bool
    @Binding var showingCreateDeck: Bool
    
    var body: some View {
        headerContent
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(headerBackground)
    }
    
    private var headerContent: some View {
        VStack(spacing: 24) {
            topSection
            controlsSection
        }
    }
    
    private var headerBackground: some View {
        Rectangle()
            .fill(Color(.systemGroupedBackground))
            .ignoresSafeArea()
    }
    
    private var topSection: some View {
        HStack {
            titleSection
            Spacer()
            addButton
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Explorer")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Organize your knowledge")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var addButton: some View {
        Button(action: addButtonAction) {
            addButtonContent
        }
    }
    
    private var addButtonContent: some View {
        Image(systemName: "plus")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(addButtonBackground)
    }
    
    private var addButtonBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.blue)
            .shadow(color: .blue.opacity(0.25), radius: 6, x: 0, y: 3)
    }
    
    private func addButtonAction() {
        if selectedMode == .notes {
            showingCreateSubject = true
        } else {
            showingCreateDeck = true
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            modeButtons
            searchBar
        }
    }
    
    private var modeButtons: some View {
        HStack(spacing: 12) {
            ForEach(ExplorerMode.allCases, id: \.self) { mode in
                modeButton(for: mode)
            }
        }
    }
    
    private func modeButton(for mode: ExplorerMode) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedMode = mode
            }
        }) {
            modeButtonContent(for: mode)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func modeButtonContent(for mode: ExplorerMode) -> some View {
        HStack(spacing: 8) {
            Image(systemName: mode.icon)
                .font(.system(size: 16, weight: .semibold))
            
            Text(mode.title)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(selectedMode == mode ? .white : .primary)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(modeButtonBackground(for: mode))
    }
    
    @ViewBuilder
    private func modeButtonBackground(for mode: ExplorerMode) -> some View {
        if selectedMode == mode {
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue)
                .overlay(modeButtonStroke(for: mode))
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(modeButtonStroke(for: mode))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    private func modeButtonStroke(for mode: ExplorerMode) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(.primary.opacity(selectedMode == mode ? 0 : 0.06), lineWidth: 1)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            searchIcon
            searchField
            clearButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(searchBarBackground)
    }
    
    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
    }
    
    private var searchField: some View {
        TextField("Search \(selectedMode.title.lowercased())...", text: $searchText)
            .font(.system(size: 16, weight: .medium))
            .textFieldStyle(PlainTextFieldStyle())
    }
    
    @ViewBuilder
    private var clearButton: some View {
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
    
    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(searchBarStroke)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private var searchBarStroke: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(.primary.opacity(0.06), lineWidth: 1)
    }
}
struct ModernExplorerSubjectTile: View {
    let subject: ExplorerSubject
    @State private var isPressed = false
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(subject.color.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: subject.imageName ?? "book.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(subject.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text(subject.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        
                        Text("\(subject.noteCount) notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                SubjectDetailView(subject: subject)
            }
        }
    }
}

struct ModernExplorerDeckTile: View {
    let deck: ExplorerDeck
    @State private var isPressed = false
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 4)
                            .frame(width: 56, height: 56)
                        
                        Circle()
                            .trim(from: 0, to: deck.masteryLevel)
                            .stroke(
                                deck.color,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: deck.masteryLevel)
                        
                        Text("\(Int(deck.masteryLevel * 100))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(deck.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text(deck.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        
                        Text("\(deck.cardCount) cards")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(deck.color)
                        
                        Text("\(Int(deck.masteryLevel * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(deck.color)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                DeckDetailView(deck: deck)
            }
        }
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
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    if let subject = note.subject {
                        HStack {
                            Text(subject)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.blue.opacity(0.08))
                                )
                            
                            Spacer()
                        }
                    }
                    
                    Text(note.title ?? "Untitled Note")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                    
                    if let dateModified = note.dateModified {
                        Text(dateModified.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 24)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 0.5)
                    .padding(.bottom, 24)
                
                Text(note.body ?? "")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeckDetailView: View {
    let deck: ExplorerDeck
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingARReview = false
    
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
                Menu {
                    Button(action: {
                        showingARReview = true
                    }) {
                        Label("Review in AR", systemImage: "arkit")
                    }
                    
                    Button(action: {
                    }) {
                        Label("Add Flashcard", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingARReview) {
            ARFlashcardReviewView(flashcards: flashcards, isPresented: $showingARReview)
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

struct NotesExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        NotesExplorerView()
            .environment(\.managedObjectContext, CoreDataService.shared.context)
            .environmentObject(StatsService())
            .environmentObject(AuthService())
    }
}
