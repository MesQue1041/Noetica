//
//  DecksView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI
import CoreData

struct DeckModel: Identifiable {
    var id = UUID()
    var name: String
    var subject: String
    var mastery: Double
    var color: Color
}

struct DecksView: View {
    @State private var decks: [DeckModel] = [
        DeckModel(name: "Biology Basics", subject: "Science", mastery: 0.15, color: .red),
        DeckModel(name: "World War II", subject: "History", mastery: 0.6, color: .blue),
        DeckModel(name: "Calculus I", subject: "Math", mastery: 1.0, color: .green)
    ]
    
    @State private var filter: String = "All"
    @State private var showAddDeck = false

    let filters = ["All", "Due", "In Progress", "Mastered"]

    var filteredDecks: [DeckModel] {
        switch filter {
        case "Due": return decks.filter { $0.mastery < 0.2 }
        case "In Progress": return decks.filter { $0.mastery >= 0.2 && $0.mastery < 0.8 }
        case "Mastered": return decks.filter { $0.mastery >= 0.8 }
        default: return decks
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Decks")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                    }
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
                .padding([.top, .horizontal])

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(filters, id: \.self) { f in
                            Button(action: { filter = f }) {
                                Text(f)
                                    .font(.caption)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 18)
                                    .background(filter == f ? Color.blue.opacity(0.2) : Color.gray.opacity(0.13))
                                    .foregroundColor(filter == f ? Color.blue : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
                
                ScrollView {
                    VStack(spacing: 22) {
                        ForEach(filteredDecks) { deck in
                            DeckCardView(deck: deck)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 2)
                    .padding(.bottom, 72)
                }
            }
            HStack {
                Spacer()
                Button(action: { showAddDeck = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Deck")
                            .bold()
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(18)
                    .shadow(radius: 6)
                }
                .padding(.bottom, 24)
                .padding(.trailing, 24)
                .sheet(isPresented: $showAddDeck) {
                    Text("Deck Creation  Soon")
                        .font(.largeTitle)
                        .padding()
                }
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

struct DeckCardView: View {
    let deck: DeckModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(deck.subject.uppercased())
                    .font(.caption2)
                    .bold()
                    .padding(7)
                    .background(deck.color.opacity(0.17))
                    .foregroundColor(deck.color)
                    .cornerRadius(10)
                Spacer()
            }
            Text(deck.name)
                .font(.title2)
                .bold()
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray5)).frame(height: 8)
                Capsule().fill(deck.color).frame(width: CGFloat(deck.mastery) * 220, height: 8)
            }
            .frame(height: 8)
            .padding(.top, 8)
            
            HStack {
                Text("\(Int(deck.mastery * 100))% Mastery")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                }) {
                    Text("Review")
                        .bold()
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 28)
                        .background(deck.color)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 7)
    }
}

struct DecksView_Previews: PreviewProvider {
    static var previews: some View {
        DecksView()
    }
}
