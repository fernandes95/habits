//
//  AllHabitsContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 31/10/2026.
//

import SwiftUI

/// Every saved habit grouped by frequency, without a status, only how often it repeats and the way to its detail
struct AllHabitsContentView: View {
    let list: [Habit]
    /// True once the habits are loaded and there are none
    var isEmptyStateVisible: Bool = false
    /// Calendar with the configured first day of the week
    let calendar: Calendar
    /// True when the habit's location reminder can't remind, `Always` location isn't allowed
    let isLocationReminderPaused: (Habit) -> Bool
    /// True when the habit's reminder hours can't remind, notifications aren't allowed
    let isNotificationReminderPaused: (Habit) -> Bool
    var onItemAction: (Habit) -> Void

    var body: some View {
        if self.isEmptyStateVisible {
            HabitsEmptyView()
        } else {
            self.habitsList
        }
    }

    private var habitsList: some View {
        List {
            ForEach(Habit.Frequency.allCases) { frequency in
                let habits = self.list.filter { $0.frequency == frequency }
                if !habits.isEmpty {
                    Section {
                        ForEach(habits, id: \.id) { habit in
                            AllHabitsRow(
                                habit: habit,
                                calendar: self.calendar,
                                isLocationReminderPaused: self.isLocationReminderPaused(habit),
                                isNotificationReminderPaused: self.isNotificationReminderPaused(habit),
                                action: { self.onItemAction(habit) }
                            )
                        }
                    } header: {
                        AllHabitsSectionHeader(frequency: frequency, count: habits.count)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(16)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: Frequency style
extension Habit.Frequency {
    /// Title of the frequency's group in all habits
    var groupTitle: LocalizedStringKey {
        switch self {
        case .daily: "habits_all_section_daily"
        case .weekly: "habit_frequency_week_days"
        case .interval: "habit_frequency_interval"
        case .minDays: "habit_min_days"
        }
    }

    var systemImage: String {
        switch self {
        case .daily: "repeat"
        case .weekly: "calendar"
        case .interval: "clock.arrow.circlepath"
        case .minDays: "target"
        }
    }

    var tint: Color {
        switch self {
        case .daily: .blue
        case .weekly: .indigo
        case .interval: .teal
        case .minDays: .orange
        }
    }
}

/// Coloured icon, frequency name and how many habits it has
private struct AllHabitsSectionHeader: View {
    let frequency: Habit.Frequency
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: self.frequency.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(self.frequency.tint, in: RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
            Text(self.frequency.groupTitle)
                .font(.subheadline.weight(.semibold))
            Text("· \(self.count)")
                .font(.subheadline)
        }
        .foregroundStyle(.secondary)
        .textCase(nil)
        .padding(.leading, -16)
    }
}

/// Habit name, how often it repeats, its goal and reminders
private struct AllHabitsRow: View {
    let habit: Habit
    let calendar: Calendar
    let isLocationReminderPaused: Bool
    let isNotificationReminderPaused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 8) {
                Text(self.habit.name)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                self.details
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        HStack(spacing: 8) {
            switch self.habit.frequency {
            case .daily:
                EmptyView()
            case .weekly:
                AllHabitsWeekDays(days: self.habit.repeatWeekDays, calendar: self.calendar, tint: self.habit.frequency.tint)
            case .interval:
                Text(self.intervalText)
            case .minDays:
                Text("habits_all_min_days \(self.habit.frequencyType.minimumDays)")
            }

            if let goal = self.habit.goal {
                Text("\(goal.value)×")
                    .fontWeight(.semibold)
            }

            if !self.habit.reminderHours.isEmpty {
                Image(systemName: self.isNotificationReminderPaused ? "bell.slash" : "bell")
            }

            if self.habit.location != nil && self.habit.hasLocationReminder {
                Image(systemName: self.isLocationReminderPaused ? "location.slash.fill" : "location.fill")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var intervalText: LocalizedStringKey {
        let days = self.habit.scheduleInterval ?? 0
        return switch days {
        case 7: "habits_all_interval_week"
        case 30: "habits_all_interval_month"
        default: "habits_all_interval_days \(days)"
        }
    }
}

/// First letter of each day of the week, the days the habit repeats on in `tint`
private struct AllHabitsWeekDays: View {
    let days: Set<WeekDay>
    let calendar: Calendar
    let tint: Color

    @Environment(\.locale) private var locale

    /// Every day starting on the configured first day of the week
    private var weekDays: [WeekDay] {
        let first = self.calendar.firstWeekday
        return (0..<7).compactMap { WeekDay(rawValue: (first - 1 + $0) % 7 + 1) }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(self.weekDays) { day in
                Text(self.letter(of: day))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(self.days.contains(day) ? AnyShapeStyle(self.tint) : AnyShapeStyle(.tertiary))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            self.weekDays
                .filter { self.days.contains($0) }
                .map { $0.localizedName(locale: self.locale) }
                .formatted(.list(type: .and).locale(self.locale))
        )
    }

    private func letter(of day: WeekDay) -> String {
        var calendar = Calendar.current
        calendar.locale = self.locale
        return calendar.veryShortStandaloneWeekdaySymbols[day.rawValue - 1]
    }
}
