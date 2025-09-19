//
//  CalendarView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var selectedDate = Date()
    @State private var activityData: [Date: Int] = [:]
    @State private var events: [CalendarEvent] = []
    @State private var isAnimating = false
    @State private var showingDatePicker = false
    @State private var showingEventCreation = false
    @State private var selectedTimeSlot: Date?
    @EnvironmentObject private var statsService: StatsService
    @Namespace private var ns
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calendar")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Track your study sessions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedDate = Date()
                                }
                            }) {
                                Text("Today")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        MonthNavigationView(selectedDate: $selectedDate, showingDatePicker: $showingDatePicker)
                            .padding(.horizontal, 24)
                    }
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            ForEach(weekdaySymbols, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        let cells = daysInMonth(for: selectedDate)
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(cells.indices, id: \.self) { idx in
                                if let date = cells[idx] {
                                    let key = calendar.startOfDay(for: date)
                                    ModernDayCell(
                                        date: date,
                                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                        isToday: calendar.isDateInToday(date),
                                        activityCount: activityData[key] ?? 0,
                                        onTap: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                selectedDate = date
                                            }
                                        }
                                    )
                                } else {
                                    Color.clear
                                        .frame(height: 50)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    SelectedDateCard(selectedDate: selectedDate, activityCount: activityData[calendar.startOfDay(for: selectedDate)] ?? 0)
                        .padding(.horizontal, 20)
                    
                    EventsForDateView(
                        selectedDate: selectedDate,
                        events: eventsForDate(selectedDate),
                        onTimeSlotTap: { time in
                            selectedTimeSlot = time
                            showingEventCreation = true
                        }
                    )
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            selectedTimeSlot = selectedDate
                            showingEventCreation = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("Create Event")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        HStack(spacing: 16) {
                            QuickEventButton(
                                icon: "book.fill",
                                title: "Study Session",
                                color: .blue,
                                action: { createQuickEvent(type: .studySession) }
                            )
                            
                            QuickEventButton(
                                icon: "rectangle.stack.fill",
                                title: "Flashcards",
                                color: .green,
                                action: { createQuickEvent(type: .flashcards) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
            .sheet(isPresented: $showingEventCreation) {
                StreamlinedEventCreationSheet(
                    selectedDate: selectedTimeSlot ?? selectedDate,
                    events: $events,
                    isPresented: $showingEventCreation
                )
            }
            .onAppear {
                loadActivityData()
                loadCalendarEvents()
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
        
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols
    }
        
    private func loadActivityData() {
        let sessions = CoreDataService.shared.fetchCompletedSessions(
            from: Calendar.current.date(byAdding: .day, value: -42, to: Date()) ?? Date(),
            to: Date()
        )
        
        activityData.removeAll()
        for session in sessions {
            if let startDate = session.startTime {
                let key = calendar.startOfDay(for: startDate)
                activityData[key, default: 0] += 1
            }
        }
    }

    
    private func loadCalendarEvents() {
        events = CoreDataService.shared.fetchCalendarEvents()
    }

    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        return events.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: date)
        }
        .sorted { $0.startTime < $1.startTime }
    }

    
    private func createQuickEvent(type: EventType) {
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        
        let startTime = calendar.date(bySettingHour: calendar.component(.hour, from: nextHour), minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let endTime = startTime.addingTimeInterval(type == .studySession ? 3600 : 1800)
        
        let title = type == .studySession ? "Quick Study Session" : "Quick Flashcard Review"
        
        let newEvent = CoreDataService.shared.createCalendarEvent(
            title: title,
            description: "Quick session created from calendar",
            startTime: startTime,
            endTime: endTime,
            type: type,
            subject: type == .studySession ? "General" : nil,
            deckName: type == .flashcards ? "General" : nil,
            autoCreateSession: true
        )
        
        events.append(newEvent)
    }
    
    private func monthYearString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
    
    private func shiftMonth(by value: Int, from date: Date) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }
    
    private func daysInMonth(for date: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        
        var result: [Date?] = []
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let lead = ((firstWeekday - calendar.firstWeekday) % 7 + 7) % 7
        
        result.append(contentsOf: Array(repeating: nil, count: lead))
        
        var current = interval.start
        while current < interval.end {
            result.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return result
    }
}

struct MonthNavigationView: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedDate = shiftMonth(by: -1, from: selectedDate)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            Spacer()
            
            Button(action: {
                showingDatePicker = true
            }) {
                Text(monthYearString(from: selectedDate))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedDate = shiftMonth(by: 1, from: selectedDate)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
    }
    
    private func shiftMonth(by value: Int, from date: Date) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }
    
    private func monthYearString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
}

struct ModernDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let activityCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                Circle()
                    .fill(activityCount > 0 ? activityColor : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 44, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(Calendar.current.component(.day, from: date))")
        .accessibilityValue(activityCount > 0 ? "\(activityCount) study sessions" : "No sessions")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select this date")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isToday && !isSelected {
            return .blue
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isToday && !isSelected ? 2 : 0
    }
    
    private var activityColor: Color {
        switch activityCount {
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.6)
        case 3: return Color.green
        case 4: return Color.orange
        case 5...: return Color.red
        default: return Color.clear
        }
    }
}

struct SelectedDateCard: View {
    let selectedDate: Date
    let activityCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(activityDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ActivityIndicator(count: activityCount)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var activityDescription: String {
        switch activityCount {
        case 0: return "No study sessions"
        case 1: return "1 study session"
        default: return "\(activityCount) study sessions"
        }
    }
}

struct ActivityIndicator: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < count ? activityColor : Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var activityColor: Color {
        switch count {
        case 1: return Color.green.opacity(0.6)
        case 2: return Color.green
        case 3: return Color.yellow
        case 4: return Color.orange
        case 5...: return Color.red
        default: return Color.gray.opacity(0.2)
        }
    }
}

struct EventsForDateView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let onTimeSlotTap: (Date) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Events for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if events.isEmpty {
                EmptyEventsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(events) { event in
                        EventCard(event: event)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct EmptyEventsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No events scheduled")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct EventCard: View {
    let event: CalendarEvent
    @StateObject private var timerService = PomodoroTimerService.shared
    @State private var currentTime = Date()
    @State private var refreshTimer: Timer?
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Circle()
                    .fill(event.type.defaultColor)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(event.type.defaultColor.opacity(0.3))
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if event.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    } else if isSessionActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .scaleEffect(timerService.isRunning ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: timerService.isRunning)
                            
                            Text(timerService.formattedTime)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    } else if canStartNow {
                        Button(action: {
                            NavigationService.shared.navigateToTimer(with: event)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
                    }
                }
                
                Text("\(event.startTime.formatted(date: .omitted, time: .shortened)) - \(event.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let subject = event.subject {
                    Text("Subject: \(subject)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                } else if let deckName = event.deckName {
                    Text("Deck: \(deckName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(canStartNow ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .onAppear {
            startUIRefreshTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
        }
    }
    
    private var canStartNow: Bool {
        let now = currentTime
        let isInWindow = now >= event.startTime && now <= event.endTime
        return !event.isCompleted && isInWindow && !isSessionActive
    }
    
    private var isSessionActive: Bool {
        return timerService.currentEvent?.id == event.id && timerService.isRunning
    }
    
    private func startUIRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

extension View {
    func pulse() -> some View {
        self.scaleEffect(1.1)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
    }
}




struct QuickEventButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)")
        .accessibilityHint("Create a quick \(title.lowercased()) session")
        .frame(minWidth: 44, minHeight: 44)
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}


struct StreamlinedEventCreationSheet: View {
    let selectedDate: Date
    @Binding var events: [CalendarEvent]
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var eventType: EventType = .studySession
    @State private var title: String = ""
    @State private var startTime = Date()
    @State private var duration: TimeInterval = 3600
    @State private var selectedSubject: String = ""
    @State private var selectedDeck: Deck?
    @State private var availableSubjects: [String] = []
    @State private var availableDecks: [Deck] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Type")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                Button(action: {
                                    eventType = type
                                    updateTitle()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(eventType == type ? .white : type.defaultColor)
                                        
                                        Text(type.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(eventType == type ? .white : type.defaultColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 70)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(eventType == type ? type.defaultColor : Color(.secondarySystemGroupedBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(type.defaultColor.opacity(eventType == type ? 0 : 0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    if eventType == .studySession {
                        studySubjectSection
                    } else {
                        flashcardDeckSection
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Schedule")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Text("Start")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Duration")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(duration/60)) minutes")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                
                                Slider(value: $duration, in: 60...7200, step: 60)
                                    .tint(eventType.defaultColor)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createEvent()
                    }
                    .disabled(!isValidEvent)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadData()
            setupInitialValues()
            updateTitle()
        }
    }
    
    private var studySubjectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Subject")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            if availableSubjects.isEmpty {
                TextField("Subject Name", text: $selectedSubject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                VStack {
                    Picker("Subject", selection: $selectedSubject) {
                        Text("Select Subject").tag("")
                        ForEach(availableSubjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Or enter new subject", text: $selectedSubject)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    private var flashcardDeckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flashcard Deck")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            if availableDecks.isEmpty {
                Text("No decks available. Create a deck first.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            } else {
                Picker("Deck", selection: $selectedDeck) {
                    Text("Select Deck").tag(nil as Deck?)
                    ForEach(availableDecks, id: \.id) { deck in
                        Text(deck.name ?? "Unnamed Deck").tag(deck as Deck?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    private var isValidEvent: Bool {
        switch eventType {
        case .studySession:
            return !selectedSubject.isEmpty
        case .flashcards:
            return selectedDeck != nil
        }
    }
    
    private func loadData() {
        availableSubjects = CoreDataService.shared.getUniqueSubjects()
        availableDecks = CoreDataService.shared.fetchDecks()
    }
    
    private func setupInitialValues() {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(selectedDate, inSameDayAs: now) {
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            startTime = calendar.date(bySettingHour: calendar.component(.hour, from: nextHour), minute: 0, second: 0, of: nextHour) ?? now
        } else {
            startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        }
    }
    
    private func updateTitle() {
        switch eventType {
        case .studySession:
            title = selectedSubject.isEmpty ? "Study Session" : "Study: \(selectedSubject)"
        case .flashcards:
            title = selectedDeck?.name.map { "Flashcards: \($0)" } ?? "Flashcard Review"
        }
    }
    
    private func createEvent() {
        let startDateTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: startTime),
            minute: Calendar.current.component(.minute, from: startTime),
            second: 0,
            of: selectedDate
        ) ?? selectedDate
        
        let endDateTime = startDateTime.addingTimeInterval(duration)
        
        let newEvent = CoreDataService.shared.createCalendarEvent(
            title: title,
            description: "Created from calendar",
            startTime: startDateTime,
            endTime: endDateTime,
            type: eventType,
            subject: eventType == .studySession ? selectedSubject : nil,
            deckName: eventType == .flashcards ? selectedDeck?.name : nil,
            autoCreateSession: true
        )
        
        events.append(newEvent)
        isPresented = false
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthService())
        .environmentObject(StatsService())
}
