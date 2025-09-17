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
                                
                                Text("Track your productivity")
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
                        
                        MonthNavigationView(
                            selectedDate: $selectedDate,
                            showingDatePicker: $showingDatePicker
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            ForEach(weekDaySymbols(), id: \.self) { day in
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
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
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
                                icon: "timer.circle.fill",
                                title: "Pomodoro",
                                color: .red,
                                action: {
                                    createQuickEvent(type: .pomodoro)
                                }
                            )
                            
                            QuickEventButton(
                                icon: "book.fill",
                                title: "Study",
                                color: .blue,
                                action: {
                                    createQuickEvent(type: .study)
                                }
                            )
                            
                            QuickEventButton(
                                icon: "rectangle.stack.fill",
                                title: "Flashcards",
                                color: .green,
                                action: {
                                    createQuickEvent(type: .flashcards)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
        .sheet(isPresented: $showingEventCreation) {
            EventCreationSheet(
                selectedDate: selectedTimeSlot ?? selectedDate,
                events: $events
            )
        }
        .onAppear {
            loadActivityData()
            loadSampleEvents()
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }


    private func loadActivityData() {
        let today = Date()
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                activityData[calendar.startOfDay(for: date)] = Int.random(in: 0...5)
            }
        }
    }
    
    private func loadSampleEvents() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: selectedDate)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        
        let pomodoroSessions = CoreDataService.shared.fetchCompletedSessions(from: startOfToday, to: endOfToday)
        
        events = pomodoroSessions.map { session in
            let sessionType: CalendarEvent.EventType = session.sessionType == "Work" ? .pomodoro : .breakTime
            
            return CalendarEvent(
                title: "\(session.sessionType ?? "Study") - \(session.subjectOrDeck ?? "General")",
                description: "Completed pomodoro session",
                startTime: session.startTime ?? startOfToday,
                endTime: session.endTime ?? session.startTime?.addingTimeInterval(TimeInterval(session.duration * 60)) ?? startOfToday,
                type: sessionType,
                color: sessionType.defaultColor
            )
        }
        
        if events.isEmpty {
            events = [
                CalendarEvent(
                    title: "Morning Study Session",
                    description: "Review calculus concepts",
                    startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate,
                    endTime: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: selectedDate) ?? selectedDate,
                    type: .study,
                    color: .blue
                )
            ]
        }
    }

    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        return events.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
    }
    
    private func createQuickEvent(type: CalendarEvent.EventType) {
        let startTime = calendar.date(bySettingHour: calendar.component(.hour, from: Date()), minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let duration: TimeInterval = type == .pomodoro ? 25 * 60 : 60 * 60 
        let endTime = startTime.addingTimeInterval(duration)
        
        let newEvent = CalendarEvent(
            title: type.rawValue,
            description: "Quick \(type.rawValue.lowercased()) session",
            startTime: startTime,
            endTime: endTime,
            type: type,
            color: type.defaultColor
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
        let lead = (firstWeekday - calendar.firstWeekday + 7) % 7
        result.append(contentsOf: Array(repeating: nil, count: lead))

        var current = interval.start
        while current < interval.end {
            result.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return result
    }

    private func weekDaySymbols() -> [String] {
        let s = calendar.shortStandaloneWeekdaySymbols
        return Array(s[calendar.firstWeekday-1..<s.count]) + s[0..<calendar.firstWeekday-1]
    }
}

struct MonthNavigationView: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedDate = shiftMonth(by: -1, from: selectedDate)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
            
            Spacer()
            
            Button(action: {
                showingDatePicker = true
            }) {
                VStack(spacing: 2) {
                    Text(monthYearString(from: selectedDate))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Tap to change")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedDate = shiftMonth(by: 1, from: selectedDate)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
    
    private func shiftMonth(by value: Int, from date: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: value, to: date) ?? date
    }
}

struct ModernDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let activityCount: Int
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
                        .overlay(
                            Circle()
                                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            HStack(spacing: 2) {
                ForEach(0..<min(activityCount, 4), id: \.self) { index in
                    Circle()
                        .fill(getActivityColor(for: index))
                        .frame(width: 4, height: 4)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.05), value: isSelected)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 50)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private func getActivityColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        case 3: return .purple
        default: return .gray
        }
    }
}

struct SelectedDateCard: View {
    let selectedDate: Date
    let activityCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Date")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(formatSelectedDate(selectedDate))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Activities")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text("\(activityCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            
            if activityCount > 0 {
                HStack(spacing: 8) {
                    ForEach(0..<min(activityCount, 4), id: \.self) { index in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(getActivityColor(for: index))
                                .frame(width: 8, height: 8)
                            
                            Text(getActivityName(for: index))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func getActivityColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        case 3: return .purple
        default: return .gray
        }
    }
    
    private func getActivityName(for index: Int) -> String {
        switch index {
        case 0: return "Study"
        case 1: return "Exercise"
        case 2: return "Work"
        case 3: return "Personal"
        default: return "Other"
        }
    }
}

struct EventsForDateView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let onTimeSlotTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let timeSlots = Array(8...22)
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(formatDate(selectedDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.secondary)
                    
                    Text("No events scheduled")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Tap + to create your first event")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                )
            } else {
                LazyVStack(spacing: 8) {
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
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

struct EventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(formatTime(event.startTime))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(formatTime(event.endTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 4)
                .frame(maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: event.type.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(event.color)
                    
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(event.type.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(event.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(event.color.opacity(0.1))
                    )
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
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
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


struct EventCreationSheet: View {
    let selectedDate: Date
    @Binding var events: [CalendarEvent]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: CalendarEvent.EventType = .study
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedColor: Color = .blue
    
    private let colors: [Color] = [.blue, .red, .green, .orange, .purple, .yellow, .pink, .cyan]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Type")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(CalendarEvent.EventType.allCases, id: \.self) { type in
                                Button(action: {
                                    selectedType = type
                                    selectedColor = type.defaultColor
                                    if title.isEmpty {
                                        title = type.rawValue
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(selectedType == type ? .white : type.defaultColor)
                                        
                                        Text(type.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedType == type ? .white : type.defaultColor)
                                            .lineLimit(1)
                                    }
                                    .frame(height: 70)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedType == type ? type.defaultColor : Color(.secondarySystemGroupedBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(type.defaultColor.opacity(selectedType == type ? 0 : 0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Details")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 16) {
                            TextField("Event title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16, weight: .medium))
                            
                            TextField("Description (optional)", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 14, weight: .regular))
                                .lineLimit(3, reservesSpace: true)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Text("Start:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                                    .labelsHidden()
                                    .onChange(of: startTime) { newValue in
                                        if endTime <= newValue {
                                            endTime = newValue.addingTimeInterval(3600)
                                        }
                                    }
                            }
                            
                            HStack {
                                Text("End:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                                    .labelsHidden()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                        )
                                        .scaleEffect(selectedColor == color ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor == color)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
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
        
        endTime = startTime.addingTimeInterval(3600) 
    }
    
    private func saveEvent() {
        let newEvent = CalendarEvent(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: selectedType,
            color: selectedColor
        )
        
        events.append(newEvent)
        presentationMode.wrappedValue.dismiss()
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}



struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .preferredColorScheme(.light)
    }
}
