//
//  HabitCalendarView.swift
//  Habits
//
//  Created by Tiago Fernandes on 12/09/2026.
//

import SwiftUI

struct HabitCalendarView: View {
    private let calendar: Calendar = .current
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let startDate: Date
    private let dates: [Date]

    @State
    private var selectedMonth: Date = .now

    init(startDate: Date, dates: [Date]) {
        self.startDate = startDate
        self.dates = dates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            self.header

            LazyVGrid(columns: self.columns, spacing: 6) {
                ForEach(self.days) { day in
                    DaySquare(state: self.state(for: day))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: self.selectedMonth)
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text(self.monthTitle)
                .font(.title2.bold())

            Spacer()

            Button(action: self.previousMonth) {
                Image(systemName: "chevron.left")
            }
            .disabled(!self.canGoToPreviousMonth)
            .opacity(self.canGoToPreviousMonth ? 1 : 0.25)

            Button(action: self.nextMonth) {
                Image(systemName: "chevron.right")
            }
            .disabled(!self.canGoToNextMonth)
            .opacity(self.canGoToNextMonth ? 1 : 0.25)
        }
        .font(.title3.weight(.semibold))
        .buttonStyle(.plain)
    }

    private var monthTitle: String {
        let title: String = self.selectedMonth.formatted(.dateTime.month(.wide))
        let isCurrentYear: Bool = self.calendar.isDate(
            self.selectedMonth,
            equalTo: .now,
            toGranularity: .year
        )

        guard !isCurrentYear else { return title.capitalized }

        return "\(title.capitalized) \(self.selectedMonth.formatted(.dateTime.year()))"
    }

    /// First day of the month the habit was created in.
    private var startMonth: Date {
        self.calendar.dateInterval(of: .month, for: self.startDate)?.start ?? self.startDate.startOfDay
    }

    /// First day of the month currently on screen.
    private var selectedMonthStart: Date {
        self.calendar.dateInterval(of: .month, for: self.selectedMonth)?.start ?? self.selectedMonth.startOfDay
    }

    private var canGoToPreviousMonth: Bool {
        self.selectedMonthStart > self.startMonth
    }

    private var canGoToNextMonth: Bool {
        guard let lastDate: Date = self.dates.max(),
              let lastMonth: Date = self.calendar.dateInterval(of: .month, for: lastDate)?.start
         else { return false }

         return self.selectedMonthStart < lastMonth
    }

    /// Every cell of the grid: leading placeholders to align the 1st day on the right
    /// weekday column, followed by one cell per day of the month.
    private var days: [Day] {
        guard let monthStart: Date = self.calendar.dateInterval(of: .month, for: self.selectedMonth)?.start,
              let range: Range<Int> = self.calendar.range(of: .day, in: .month, for: self.selectedMonth)
        else { return [] }

        let weekday: Int = self.calendar.component(.weekday, from: monthStart)
        let leadingCount: Int = (weekday - self.calendar.firstWeekday + 7) % 7

        var result: [Day] = (0..<leadingCount).map { Day(index: -($0 + 1), date: nil) }

        for offset in 0..<range.count {
            guard let date = self.calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            result.append(Day(index: offset, date: date))
        }

        return result
    }

    private func state(for day: Day) -> DaySquare.State {
        guard let date: Date = day.date else { return .placeholder }
        return self.dates.contains(where: {
            $0.startOfDay == date.startOfDay
        }) ? .completed : .placeholder
    }

    private func previousMonth() {
        guard self.canGoToPreviousMonth else { return }

        self.selectedMonth = self.calendar.date(
            byAdding: .month,
            value: -1,
            to: self.selectedMonth
        ) ?? self.selectedMonth
    }

    private func nextMonth() {
        guard self.canGoToNextMonth else { return }

        self.selectedMonth = self.calendar.date(
            byAdding: .month,
            value: 1,
            to: self.selectedMonth
        ) ?? self.selectedMonth
    }
}

private struct Day: Identifiable {
    let index: Int
    let date: Date?

    var id: Int { self.index }
}

private struct DaySquare: View {
    enum State {
        case placeholder
        case completed
    }

    let state: State

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(self.color)
            .aspectRatio(1, contentMode: .fit)
    }

    private var color: Color {
        switch self.state {
        case .placeholder: Color.gray.opacity(0.2)
        case .completed: Color.green
        }
    }
}
