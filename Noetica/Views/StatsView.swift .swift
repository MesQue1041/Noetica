//
//  StatsView.swift .swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//


import SwiftUI

struct StatsView: View {
    @State private var totalNotes = 42
    @State private var totalFlashcards = 128
    @State private var pomodoroSessions = 24
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Your Stats")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(Color.purple)
            
            HStack(spacing: 24) {
                StatCard(title: "Notes Taken", value: String(totalNotes), icon: "note.text")
                StatCard(title: "Flashcards", value: String(totalFlashcards), icon: "rectangle.stack.fill")
                StatCard(title: "Pomodoro Sessions", value: String(pomodoroSessions), icon: "timer")
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Coming Soon")
                    .font(.title3)
                    .foregroundColor(.gray)
                Text("Advanced charts and progress reports will be here.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 64)
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color.purple)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.purple)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 110, height: 140)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
