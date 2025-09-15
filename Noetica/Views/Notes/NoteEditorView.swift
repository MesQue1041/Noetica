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
    @State private var isAnimating = false
    @State private var showingSaveAnimation = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, subject, tags, body
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Note")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Last modified: \(formatDate(note.dateModified ?? Date()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    VStack(spacing: 20) {
                        ModernInputCard(
                            title: "Title",
                            icon: "doc.text.fill",
                            iconColor: .blue
                        ) {
                            TextField("Enter note title...", text: Binding(
                                get: { note.title ?? "" },
                                set: { note.title = $0 }
                            ))
                            .focused($focusedField, equals: .title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        }
                        
                        ModernInputCard(
                            title: "Subject",
                            icon: "book.fill",
                            iconColor: .green
                        ) {
                            TextField("Enter subject...", text: Binding(
                                get: { note.subject ?? "" },
                                set: { note.subject = $0 }
                            ))
                            .focused($focusedField, equals: .subject)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        }
                        
                        ModernInputCard(
                            title: "Tags",
                            icon: "tag.fill",
                            iconColor: .orange
                        ) {
                            TextField("Add tags (comma separated)...", text: Binding(
                                get: { note.tags ?? "" },
                                set: { note.tags = $0 }
                            ))
                            .focused($focusedField, equals: .tags)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Content")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            TextEditor(text: Binding(
                                get: { note.body ?? "" },
                                set: { note.body = $0 }
                            ))
                            .focused($focusedField, equals: .body)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                            .frame(minHeight: 200)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .body ? Color.purple : Color(.systemGray4), lineWidth: focusedField == .body ? 2 : 1)
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: focusedField)
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: saveNote) {
                            HStack(spacing: 12) {
                                if showingSaveAnimation {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                
                                Text(showingSaveAnimation ? "Saving..." : "Save Note")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: isValidNote ? [Color.purple, Color.blue] : [Color.gray, Color.gray.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: isValidNote ? Color.purple.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                            .scaleEffect(showingSaveAnimation ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: showingSaveAnimation)
                        }
                        .disabled(!isValidNote || showingSaveAnimation)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
                .padding(.top, 10)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var isValidNote: Bool {
        !(note.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
    
    private func saveNote() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingSaveAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                note.dateModified = Date()
                try viewContext.save()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSaveAnimation = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSaveAnimation = false
                }
                print("Failed to save: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ModernInputCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 20)
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
