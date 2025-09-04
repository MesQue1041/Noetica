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
            Section(header: Text("Title").fontWeight(.semibold)) {
                TextField("Title", text: Binding(
                    get: { note.title ?? "" },
                    set: { note.title = $0 }
                ))
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            
            Section(header: Text("Subject").fontWeight(.semibold)) {
                TextField("Subject", text: Binding(
                    get: { note.subject ?? "" },
                    set: { note.subject = $0 }
                ))
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            
            Section(header: Text("Tags (comma separated)").fontWeight(.semibold)) {
                TextField("Tags", text: Binding(
                    get: { note.tags ?? "" },
                    set: { note.tags = $0 }
                ))
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            
            Section(header: Text("Body").fontWeight(.semibold)) {
                TextEditor(text: Binding(
                    get: { note.body ?? "" },
                    set: { note.body = $0 }
                ))
                .frame(height: 220)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
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
                .foregroundColor(note.title == nil || note.title!.isEmpty ? .gray : Color.purple)
                .disabled(note.title == nil || note.title!.isEmpty)
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
        return NavigationView {
            NoteEditorView(note: sampleNote)
                .environment(\.managedObjectContext, context)
        }
    }
}
