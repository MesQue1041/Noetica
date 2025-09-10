//
//  CalendarView.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var activityData: [Date: Int] = [:]
    @State private var isAnimating = false
    @State private var showingDatePicker = false
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
                    
                    VStack(spacing: 16) {
                        Button(action: {}) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("Add Task")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        HStack(spacing: 16) {
                            ActionButton(
                                icon: "calendar.badge.plus",
                                title: "Event",
                                color: .green,
                                action: {}
                            )
                            
                            ActionButton(
                                icon: "bell.fill",
                                title: "Reminder",
                                color: .orange,
                                action: {}
                            )
                            
                            ActionButton(
                                icon: "chart.bar.fill",
                                title: "Stats",
                                color: .purple,
                                action: {}
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
        .onAppear {
            loadActivityData()
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

struct ActionButton: View {
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
