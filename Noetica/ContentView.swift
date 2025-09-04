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
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText: String = ""
    @State private var selectedSubject: String = "All"
    @State private var showCreatePage = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)],
        animation: .default
    )
    private var notes: FetchedResults<Note>

    private var subjectFolders: [SubjectFolder] {
        let subjects = Set(notes.compactMap { $0.subject?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let folderSubjects = selectedSubject == "All" ? subjects : Set([selectedSubject])
        return folderSubjects.sorted().map { subj in
            let notesForSubject = notes.filter {
                $0.subject == subj &&
                (searchText.isEmpty || ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false))
            }
            return SubjectFolder(subject: subj, notes: notesForSubject)
        }.filter { !$0.notes.isEmpty }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Notes")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button(action: { showCreatePage = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Add New Note or Flashcard")
                }
                .padding(.horizontal)
                .padding(.top, 12)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search notes", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        SubjectFilterButton(title: "All", isSelected: selectedSubject == "All") {
                            withAnimation { selectedSubject = "All" }
                        }
                        ForEach(Array(Set(notes.compactMap { $0.subject }).sorted()), id: \.self) { subject in
                            SubjectFilterButton(title: subject, isSelected: selectedSubject == subject) {
                                withAnimation { selectedSubject = subject }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                        ForEach(subjectFolders) { folder in
                            NavigationLink(destination: NotesListView(notes: folder.notes, subject: folder.subject)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "folder.fill")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.blue)
                                            )
                                        Spacer()
                                    }

                                    Text(folder.subject)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    Text("\(folder.notes.count) item\(folder.notes.count == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePage) {
                CreatePageView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

struct SubjectFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct NotesListView: View {
    let notes: [Note]
    let subject: String

    var body: some View {
        List(notes) { note in
            NavigationLink(destination: NoteEditorView(note: note)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title ?? "No Title")
                        .font(.headline)
                    Text(note.body ?? "")
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("\(subject)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
