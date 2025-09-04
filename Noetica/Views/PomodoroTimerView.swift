//
//  PomodoroTimerView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//



import SwiftUI

enum PomodoroSessionType: String, CaseIterable, Identifiable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var id: String { rawValue }
    var duration: Int {
        switch self {
        case .work: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
}

struct PomodoroTimerView: View {
    @State private var selectedSession: PomodoroSessionType = .work
    @State private var timeRemaining: Int = PomodoroSessionType.work.duration
    @State private var timerRunning = false
    @State private var selectedSubject: String = "Math 101 - Calculus"
    @State private var showSubjectPicker = false
    @State private var timer: Timer? = nil
    @State private var progress: Double = 1.0
    
    var body: some View {
        VStack(spacing: 28) {
            
            Text("Pomodoro")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 220, height: 220)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text(timeString(timeRemaining))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Subject")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { showSubjectPicker.toggle() }) {
                    HStack {
                        Text(selectedSubject)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $showSubjectPicker) {
                SubjectPickerView(selectedSubject: $selectedSubject)
            }
            
            HStack(spacing: 40) {
                
                Button(action: resetTimer) {
                    Circle()
                        .fill(Color(UIColor.systemGray6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundColor(.primary)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                Button(action: {
                    timerRunning ? pauseTimer() : startTimer()
                }) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                        .scaleEffect(timerRunning ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerRunning)
                }
                
                Button(action: stopTimer) {
                    Circle()
                        .fill(Color(UIColor.systemGray6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.top, 8)
            
            Button(action: {}) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title3)
                            .foregroundColor(.primary)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .onAppear(perform: resetTimer)
        .onDisappear(perform: stopTimer)
    }
    
    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                progress = Double(timeRemaining) / Double(selectedSession.duration)
            } else {
                timer?.invalidate()
                timerRunning = false
            }
        }
    }
    private func pauseTimer() {
        timerRunning = false
        timer?.invalidate()
    }
    private func stopTimer() {
        timer?.invalidate()
        timerRunning = false
    }
    private func resetTimer() {
        stopTimer()
        timeRemaining = selectedSession.duration
        progress = 1.0
    }
    private func timeString(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

struct SubjectPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedSubject: String
    @State private var subjects = ["Math 101 - Calculus", "Physics", "Programming", "History", "General"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(subjects, id: \.self) { subj in
                    Button(action: {
                        selectedSubject = subj
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(subj)
                            if subj == selectedSubject {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
    }
}
