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
    @Namespace private var ns

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        VStack(spacing: 18) {

            VStack(spacing: 6) {
                Text("Calendar")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue],
                                       startPoint: .leading, endPoint: .trailing)
                    )

                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedDate = shiftMonth(by: -1, from: selectedDate)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Text(monthYearString(from: selectedDate))
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedDate = shiftMonth(by: 1, from: selectedDate)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3.weight(.semibold))
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekDaySymbols(), id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let cells = daysInMonth(for: selectedDate)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(cells.indices, id: \.self) { idx in
                    if let date = cells[idx] {
                        let key = calendar.startOfDay(for: date)
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            activityCount: activityData[key] ?? 0,
                            onTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedDate = date
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 46)
                    }
                }
            }
            .padding(.horizontal, 6)
            .transition(.opacity.combined(with: .move(edge: .trailing)))

            Spacer(minLength: 8)

            Button(action: {}) {
                Text("Add Task")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.purple, .blue],
                                                 startPoint: .leading, endPoint: .trailing))
                            .shadow(color: .purple.opacity(0.35), radius: 12, x: 0, y: 8)
                    )
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .onAppear(perform: loadActivityData)
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


private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let activityCount: Int
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(
                        isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [.purple, .blue],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing))
                        : AnyShapeStyle(isToday ? Color.purple.opacity(0.15) : .clear)
                    )
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)

            if activityCount > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(activityCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 5, height: 5)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            } else {
                Spacer().frame(height: 5)
            }
        }
        .frame(height: 46, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .preferredColorScheme(.light)
      
    }
}
