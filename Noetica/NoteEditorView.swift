//
//  NoteEditorView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-03.
//

import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var note: Note
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Title", text: Binding(
                    get: { note.title ?? "" },
                    set: { note.title = $0 }
                ))
            }
            Section(header: Text("Subject")) {
                TextField("Subject", text: Binding(
                    get: { note.subject ?? "" },
                    set: { note.subject = $0 }
                ))
            }
            Section(header: Text("Tags (comma separated)")) {
                TextField("Tags", text: Binding(
                    get: { note.tags ?? "" },
                    set: { note.tags = $0 }
                ))
            }
            Section(header: Text("Body")) {
                TextEditor(text: Binding(
                    get: { note.body ?? "" },
                    set: { note.body = $0 }
                ))
                .frame(height: 200)
            }
        }
        .navigationTitle("Edit Note")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    do {
                        note.dateModified = Date()
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Failed to save: \(error)")
                    }
                }
            }
        }
    }
}

struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleNote = Note(context: context)
        sampleNote.title = "Sample Note"
        sampleNote.body = "You can edit the note here."
        sampleNote.subject = "Science"
        sampleNote.tags = "biology,chemistry"
        return NoteEditorView(note: sampleNote)
            .environment(\.managedObjectContext, context)
    }
}
