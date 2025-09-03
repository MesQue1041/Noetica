//
//  ContentView.swift
//  Noetica
//
//  Created by Abdul on 2025-08-22.
//

import SwiftUI
import CoreData

struct SubjectFolder: Identifiable {
    var id: String { subject }
    let subject: String
    let notes: [Note]
    // ill probably add images to this later maybe at end
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchText: String = ""
    @State private var selectedSubject: String = "All"
    @State private var showCreatePage = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: true)],
        animation: .default)
    private var notes: FetchedResults<Note>

    private var subjectFolders: [SubjectFolder] {
        let subjects = Set(notes.compactMap { $0.subject?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let folderSubjects = selectedSubject == "All" ? subjects : Set([selectedSubject])
        return folderSubjects.sorted().map { subj in
            let notesForSubject = notes.filter { $0.subject == subj && (searchText.isEmpty || ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)) }
            return SubjectFolder(subject: subj, notes: notesForSubject)
        }.filter { !$0.notes.isEmpty }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.largeTitle)
                    .bold()
                    .padding(.leading)

                TextField("Search notes", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { selectedSubject = "All" }) {
                            Text("All")
                                .padding(.vertical, 5).padding(.horizontal, 12)
                                .background(selectedSubject == "All" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(16)
                        }
                        ForEach(Array(Set(notes.compactMap { $0.subject }).sorted()), id: \.self) { subject in
                            Button(action: { selectedSubject = subject }) {
                                Text(subject)
                                    .padding(.vertical, 5).padding(.horizontal, 12)
                                    .background(selectedSubject == subject ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(subjectFolders) { folder in
                            NavigationLink(destination: NotesListView(notes: folder.notes, subject: folder.subject)) {
                                VStack {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(height: 100)
                                        .overlay(Text(folder.subject.prefix(1)).font(.system(size: 40)))
                                        .cornerRadius(12)

                                    Text("\(folder.subject) Notes")
                                        .font(.headline)
                                        .lineLimit(1)

                                    Text("\(folder.notes.count) items")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.06), radius: 5)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreatePage = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePage) {
                CreatePageView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

struct NotesListView: View {
    let notes: [Note]
    let subject: String

    var body: some View {
        List(notes) { note in
            NavigationLink(destination: NoteEditorView(note: note)) {
                VStack(alignment: .leading) {
                    Text(note.title ?? "No Title")
                        .font(.headline)
                    Text(note.body ?? "")
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
        }
        .navigationTitle("\(subject) Notes")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}





