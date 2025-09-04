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
    let filterColors: [Color] = [.purple, .orange, .blue, .green]

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
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Decks")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("\(filteredDecks.count) collection\(filteredDecks.count == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .offset(x: animateHeader ? 0 : -30)
                    .opacity(animateHeader ? 1 : 0)

                    Spacer()

                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .scaleEffect(animateHeader ? 1 : 0.8)
                        .opacity(animateHeader ? 1 : 0)

                        Button(action: {}) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .scaleEffect(animateHeader ? 1 : 0.8)
                        .opacity(animateHeader ? 1 : 0)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(filters.enumerated()), id: \.offset) { index, f in
                            Button(action: {
                                withAnimation(.spring()) {
                                    filter = f
                                    selectedFilter = index
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(filterColors[index])
                                        .frame(width: 8, height: 8)
                                        .opacity(filter == f ? 1 : 0.6)

                                    Text(f)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(filter == f ? .primary : .secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(filter == f ? Color(.systemGray5) : Color(.systemGray6))
                                )
                                .scaleEffect(filter == f ? 1.05 : 1.0)
                            }
                            .offset(y: animateFilters ? 0 : 20)
                            .opacity(animateFilters ? 1 : 0)
                            .animation(.spring().delay(Double(index) * 0.1), value: animateFilters)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }

                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(filteredDecks.enumerated()), id: \.element.objectID) { index, deck in
                            ModernDeckCardView(
                                deck: deck,
                                flashcards: flashcards(for: deck)
                            )
                            .offset(y: animateCards ? 0 : 50)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.spring().delay(Double(index) * 0.1), value: animateCards)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            HStack {
                Spacer()
                Button(action: {
                    showAddDeck = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                        Text("Add Deck")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 32)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 6)
                }
                .padding(.bottom, 40)
                .padding(.trailing, 24)
                .sheet(isPresented: $showAddDeck) {
                    DeckCreationView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            withAnimation(.easeOut(duration: 1).delay(0.2)) {
                animateFilters = true
            }
            withAnimation(.easeOut(duration: 1).delay(0.4)) {
                animateCards = true
            }
        }
    }
}

struct ModernDeckCardView: View {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text((deck.subject ?? "GENERAL").uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(subjectColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(subjectColor.opacity(0.15))
                            .cornerRadius(12)

                        Spacer()

                        Text("\(flashcards.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("cards")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text(deck.name ?? "Unnamed Deck")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }
            
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mastery Progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int((deck.mastery * 100).rounded()))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(masteryColor)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [masteryColor.opacity(0.6), masteryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(CGFloat(deck.mastery) * (UIScreen.main.bounds.width - 80), 8), height: 8)
                        .animation(.spring(), value: deck.mastery)
                }
            }
            
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                        showReview = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .medium))
                        Text("Review")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        LinearGradient(
                            colors: [masteryColor.opacity(0.8), masteryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .sheet(isPresented: $showReview) {
                    FlashcardReviewView(flashcards: flashcards)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct DecksView_Previews: PreviewProvider {
    static var previews: some View {
        DecksView()
    }
}
