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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ExplorerHeaderSection(
                    selectedMode: $selectedMode,
                    searchText: $searchText,
                    showingCreateSubject: $showingCreateSubject,
                    showingCreateDeck: $showingCreateDeck
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        if selectedMode == .notes {
                            if filteredSubjects.isEmpty {
                                ModernEmptyStateView(
                                    icon: "doc.text",
                                    title: "No Notes Yet",
                                    subtitle: "Create your first note to get started",
                                    buttonTitle: "Create Note",
                                    action: { showingCreateSubject = true }
                                )
                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 20),
                                        GridItem(.flexible(), spacing: 20)
                                    ],
                                    spacing: 24
                                ) {
                                    ForEach(filteredSubjects) { subject in
                                        ModernExplorerSubjectTile(subject: subject)
                                    }
                                }
                            }
                        } else {
                            if filteredDecks.isEmpty {
                                ModernEmptyStateView(
                                    icon: "rectangle.stack",
                                    title: "No Decks Yet",
                                    subtitle: "Create your first flashcard deck",
                                    buttonTitle: "Create Deck",
                                    action: { showingCreateDeck = true }
                                )
                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 20),
                                        GridItem(.flexible(), spacing: 20)
                                    ],
                                    spacing: 24
                                ) {
                                    ForEach(filteredDecks) { deck in
                                        ModernExplorerDeckTile(deck: deck)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 120)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
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
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
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
        VStack(spacing: 32) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explorer")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Discover & organize your knowledge")
                        .font(.system(size: 17, weight: .medium))
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                            .frame(width: 52, height: 52)
                            .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedMode)
            }
            
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(ExplorerMode.allCases, id: \.self) { mode in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedMode = mode
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text(mode.title)
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(selectedMode == mode ? .white : .primary)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedMode == mode ? Color.blue : Color(.systemBackground))
                                    .shadow(color: selectedMode == mode ? Color.blue.opacity(0.3) : Color.black.opacity(0.08), radius: selectedMode == mode ? 8 : 4, x: 0, y: selectedMode == mode ? 4 : 2)
                            )
                            .scaleEffect(selectedMode == mode ? 1.02 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search \(selectedMode.title.lowercased())...", text: $searchText)
                        .font(.system(size: 17, weight: .medium))
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .ignoresSafeArea()
        )
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
                        RoundedRectangle(cornerRadius: 20)
                            .fill(subject.color.opacity(0.15))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: subject.imageName ?? "book.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(subject.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text(subject.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(subject.color)
                            
                            Text("\(subject.noteCount) notes")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(subject.color.opacity(0.1))
                        )
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(subject.color)
                        .opacity(0.8)
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(subject.color.opacity(0.15), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
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
                            .stroke(deck.color.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: deck.masteryLevel)
                            .stroke(
                                deck.color,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: deck.masteryLevel)
                        
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(deck.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text(deck.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(deck.color)
                            
                            Text("\(deck.cardCount) cards")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(deck.color.opacity(0.1))
                        )
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack {
                    Text("\(Int(deck.masteryLevel * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(deck.color)
                                .shadow(color: deck.color.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(deck.color)
                        .opacity(0.8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(deck.color.opacity(0.15), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
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
