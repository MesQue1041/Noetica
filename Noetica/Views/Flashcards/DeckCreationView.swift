//
//  DeckCreationView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//



import SwiftUI
import CoreData

struct DeckCreationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var statsService: StatsService 

    @State private var deckName: String = ""
    @State private var deckSubject: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case name, subject
    }

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Create Deck")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.6), value: showContent)

                    Text("Add a name and subject to start organizing your flashcards.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -15)
                        .animation(.easeOut(duration: 0.7).delay(0.1), value: showContent)
                }

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Deck Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter deck name", text: $deckName)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .focused($focusedField, equals: .name)
                            .scaleEffect(focusedField == .name ? 1.01 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: focusedField)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subject")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter subject", text: $deckSubject)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .focused($focusedField, equals: .subject)
                            .scaleEffect(focusedField == .subject ? 1.01 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: focusedField)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                Spacer()

                Button(action: createDeck) {
                    Text("Create Deck")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(deckName.isEmpty || deckSubject.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(deckName.isEmpty || deckSubject.isEmpty ? 0 : 0.3), radius: 10, x: 0, y: 4)
                        .scaleEffect(deckName.isEmpty || deckSubject.isEmpty ? 1.0 : 1.03)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: deckName)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: deckSubject)
                }
                .padding(.horizontal, 40)
                .disabled(deckName.isEmpty || deckSubject.isEmpty)

                Spacer()
            }
            .padding(.top, 40)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }

    private func createDeck() {
        let newDeck = Deck(context: viewContext)
        newDeck.id = UUID()
        newDeck.name = deckName
        newDeck.subject = deckSubject
        newDeck.mastery = 0.0

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving deck: \(error.localizedDescription)")
        }
    }
}

struct DeckCreationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeckCreationView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
