//
//  DecksView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI
import CoreData

struct DecksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var animateCards = false
    @State private var animateFilters = false
    @State private var animateHeader = false
    @State private var isAnimating = false
    @State private var showingSearch = false
    @State private var searchText = ""

    @FetchRequest(
        entity: Deck.entity(),
        sortDescriptors: []
    ) private var decks: FetchedResults<Deck>

    @FetchRequest(
        entity: Flashcard.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: true)]
    ) private var allFlashcards: FetchedResults<Flashcard>

    @State private var filter: String = "All"
    @State private var showAddDeck = false
    @State private var selectedFilter = 0

    let filters = ["All", "Due", "In Progress", "Mastered"]
    let filterColors: [Color] = [.blue, .orange, .purple, .green]

    var filteredDecks: [Deck] {
        let filtered = decks.filter { deck in
            switch filter {
            case "Due":
                return deck.mastery < 0.2
            case "In Progress":
                return deck.mastery >= 0.2 && deck.mastery < 0.8
            case "Mastered":
                return deck.mastery >= 0.8
            default:
                return true
            }
        }
        return filtered.sorted(by: compareDeckNames)
    }

    private func compareDeckNames(_ a: Deck, _ b: Deck) -> Bool {
        guard let nameA = a.name, let nameB = b.name else {
            return false
        }
        return nameA.localizedCaseInsensitiveCompare(nameB) == .orderedAscending
    }

    func flashcards(for deck: Deck) -> [Flashcard] {
        allFlashcards.filter { $0.deck == deck }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Flashcard Decks")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("\(filteredDecks.count) collection\(filteredDecks.count == 1 ? "" : "s") available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showingSearch.toggle()
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.purple)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if showingSearch {
                            SearchBar(text: $searchText)
                                .padding(.horizontal, 24)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        StatsCardsView(decks: Array(decks))
                            .padding(.horizontal, 24)
                    }

                    FilterTabsView(
                        filters: filters,
                        filterColors: filterColors,
                        selectedFilter: $filter,
                        selectedIndex: $selectedFilter
                    )
                    .padding(.horizontal, 24)

                    LazyVStack(spacing: 20) {
                        ForEach(Array(filteredDecks.enumerated()), id: \.element.objectID) { index, deck in
                            ModernDeckCard(
                                deck: deck,
                                flashcards: flashcards(for: deck)
                            )
                            .scaleEffect(isAnimating ? 1.0 : 0.9)
                            .opacity(isAnimating ? 1.0 : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        showAddDeck = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("Create New Deck")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showAddDeck) {
            DeckCreationView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Search decks...", text: $text)
                .font(.system(size: 16, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
}

struct StatsCardsView: View {
    let decks: [Deck]
    
    private var totalCards: Int {
        decks.reduce(0) { $0 + ($1.flashcards?.count ?? 0) }
    }
    
    private var averageMastery: Double {
        guard !decks.isEmpty else { return 0 }
        return decks.reduce(0) { $0 + $1.mastery } / Double(decks.count)
    }
    
    private var masteredDecks: Int {
        decks.filter { $0.mastery >= 0.8 }.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            DeckStatCard(
                title: "Total Cards",
                value: "\(totalCards)",
                icon: "rectangle.stack.fill",
                color: Color.blue
            )
            
            DeckStatCard(
                title: "Avg Mastery",
                value: "\(Int(averageMastery * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: Color.green
            )
            
            DeckStatCard(
                title: "Mastered",
                value: "\(masteredDecks)",
                icon: "checkmark.seal.fill",
                color: Color.purple
            )
        }
    }
}

struct DeckStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct FilterTabsView: View {
    let filters: [String]
    let filterColors: [Color]
    @Binding var selectedFilter: String
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                    FilterTab(
                        title: filter,
                        color: filterColors[index],
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedFilter = filter
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FilterTab: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .opacity(isSelected ? 1.0 : 0.6)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? Color.white : color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(DeckScaleButtonStyle())
    }
}

struct ModernDeckCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    let deck: Deck
    let flashcards: [Flashcard]
    
    @State private var showReview = false
    @State private var isPressed = false
    
    private var masteryColor: Color {
        switch deck.mastery {
        case 0..<0.3: return .orange
        case 0.3..<0.7: return .blue
        default: return .green
        }
    }
    
    private var subjectColor: Color {
        let colors: [Color] = [.purple, .blue, .green, .orange, .pink, .indigo]
        let hash = (deck.subject?.hash ?? 0) % colors.count
        return colors[abs(hash)]
    }
    
    private var masteryLevel: String {
        switch deck.mastery {
        case 0..<0.3: return "Beginner"
        case 0.3..<0.7: return "Intermediate"
        default: return "Advanced"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text((deck.subject ?? "GENERAL").uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(subjectColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(subjectColor.opacity(0.15))
                            )
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(flashcards.count)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("cards")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(deck.name ?? "Unnamed Deck")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(masteryLevel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(masteryColor)
                    }
                    
                    Spacer()
                    
                    Text("\(Int((deck.mastery * 100).rounded()))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(masteryColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(masteryColor)
                            .frame(width: max(geometry.size.width * CGFloat(deck.mastery), 6), height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: deck.mastery)
                    }
                }
                .frame(height: 6)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                Button(action: {
                    showReview = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Review")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(masteryColor)
                    .cornerRadius(12)
                    .shadow(color: masteryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .sheet(isPresented: $showReview) {
            FlashcardReviewView(flashcards: flashcards)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

struct DeckScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DecksView_Previews: PreviewProvider {
    static var previews: some View {
        DecksView()
    }
}
