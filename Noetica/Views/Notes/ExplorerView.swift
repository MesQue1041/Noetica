//
//  ExplorerView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-11.
//

import SwiftUI

struct NotesExplorerView: View {
    @State private var selectedMode: ExplorerMode = .notes
    @State private var searchText = ""
    @State private var showingCreateSubject = false
    @State private var showingCreateDeck = false
    
    @State private var subjects = [
        ExplorerSubject(name: "Mathematics", color: .blue, noteCount: 12, imageName: "function"),
        ExplorerSubject(name: "Physics", color: .purple, noteCount: 8, imageName: "atom"),
        ExplorerSubject(name: "Chemistry", color: .green, noteCount: 15, imageName: "testtube.2"),
        ExplorerSubject(name: "Biology", color: .orange, noteCount: 6, imageName: "leaf"),
        ExplorerSubject(name: "History", color: .brown, noteCount: 10, imageName: "book.closed"),
        ExplorerSubject(name: "Literature", color: .red, noteCount: 7, imageName: "text.book.closed")
    ]
    
    @State private var decks = [
        ExplorerDeck(name: "French Vocabulary", color: .blue, cardCount: 45, masteryLevel: 0.7),
        ExplorerDeck(name: "Math Formulas", color: .purple, cardCount: 23, masteryLevel: 0.4),
        ExplorerDeck(name: "Historical Dates", color: .orange, cardCount: 67, masteryLevel: 0.8),
        ExplorerDeck(name: "Chemistry Elements", color: .green, cardCount: 34, masteryLevel: 0.6),
        ExplorerDeck(name: "Biology Terms", color: .red, cardCount: 28, masteryLevel: 0.3)
    ]
    
    var filteredSubjects: [ExplorerSubject] {
        if searchText.isEmpty {
            return subjects
        }
        return subjects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredDecks: [ExplorerDeck] {
        if searchText.isEmpty {
            return decks
        }
        return decks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                                ForEach(filteredSubjects) { subject in
                                    ExplorerSubjectTile(subject: subject)
                                }
                            } else {
                                ForEach(filteredDecks) { deck in
                                    ExplorerDeckTile(deck: deck)
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
            CreateSubjectView()
        }
        .sheet(isPresented: $showingCreateDeck) {
            CreateDeckView()
        }
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
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        
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
                                      LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing) :
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

enum ExplorerMode: CaseIterable {
    case notes, decks
    
    var title: String {
        switch self {
        case .notes: return "Notes"
        case .decks: return "Decks"
        }
    }
    
    var icon: String {
        switch self {
        case .notes: return "doc.text"
        case .decks: return "rectangle.stack"
        }
    }
}

struct ExplorerSubject: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let noteCount: Int
    let imageName: String
}

struct ExplorerDeck: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let cardCount: Int
    let masteryLevel: Double
}

struct SubjectDetailView: View {
    let subject: ExplorerSubject
    
    var body: some View {
        VStack(spacing: 20) {
            Text(subject.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Notes for \(subject.name)")
                .foregroundColor(.secondary)
            
            Text("This will show all notes for this subject")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeckDetailView: View {
    let deck: ExplorerDeck
    
    var body: some View {
        VStack(spacing: 20) {
            Text(deck.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Flashcards in \(deck.name)")
                .foregroundColor(.secondary)
            
            Text("This will show all flashcards in this deck")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreateSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create New Subject")
                    .font(.title)
                    .padding()
                
                Text("Subject creation form will be here")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create New Deck")
                    .font(.title)
                    .padding()
                
                Text("Deck creation form will be here")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NotesExplorerView()
}
