//
//  HabitFrequencyView.swift
//  Habits
//
//  Created by Tiago Fernandes on 27/12/2024.
//

import SwiftUI

struct HabitFrequencyView: View {
    @Binding private var habit: Habit
    @Binding private var isEditing: Bool

    @Environment(\.locale)
    private var locale: Locale

    @EnvironmentObject
    private var state: MainState

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    init(habit: Binding<Habit>, isEditing: Binding<Bool>) {
        self._habit = habit
        self._isEditing = isEditing
    }

    var body: some View {
        Section {
            Picker("habit_frequency", selection: self.pickerFrequency) {
                // Weekly is not picked, it comes from the selected week days
                ForEach(Habit.Frequency.allCases.filter { $0 != .weekly }) { frequency in
                    Text(frequency == .daily ? "habit_frequency_week_days" : frequency.title).tag(frequency)
                }
            }
            .accessibilityIdentifier("habit_frequency")
            .onChange(of: self.habit.frequency) { _, frequency in
                if frequency != .weekly {
                    self.habit.frequencyType.weekFrequency.removeAll()
                }
                if frequency != .interval {
                    self.habit.scheduleInterval = nil
                }
                if frequency != .minDays {
                    self.habit.frequencyType.minimumDays = 0
                }
            }
            .disabled(!isEditing)

            switch self.habit.frequency {
            case .daily, .weekly:
                self.weekDaysView
            case .interval:
                if isEditing {
                    TextField("habit_interval_title", value: self.$habit.scheduleInterval, formatter: self.formatter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("new_habit_schedule_interval")
                        .disabled(!isEditing)
                } else {
                    HStack {
                        Text("habit_interval_title")
                        Spacer()
                        Text("\(String(self.habit.scheduleInterval ?? 0))")
                            .accessibilityIdentifier("habit_interval_value")
                    }
                }
            case .minDays:
                TextField("habit_min_days", text: self.numberText(self.$habit.frequencyType.minimumDays))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("habit_min_days")
                    .disabled(!isEditing)
            }
        } header: {
            Text("habit_new_section_habit_frequency")
        } footer: {
            if self.isWeekDaysFrequency {
                self.weekDaysFooter
            }
        }

        if isEditing || self.habit.goal != nil {
            self.goalSection
        }

        if isEditing || self.habit.hasAlarm {
            HabitReminderSectionView(habit: self.$habit, isEditing: isEditing)
        }
    }

    /// Text binding for a whole number field, so the habit updates on every keystroke
    /// and not only when the field loses focus. `0` shows as an empty field so the placeholder is visible.
    private func numberText(_ value: Binding<Int>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue == 0 ? "" : String(value.wrappedValue) },
            set: { value.wrappedValue = Int($0.filter(\.isNumber)) ?? 0 }
        )
    }
}

extension HabitFrequencyView {
    // MARK: Week days

    /// Daily and weekly are both picked with the week days option
    private var isWeekDaysFrequency: Bool {
        self.habit.frequency == .daily || self.habit.frequency == .weekly
    }

    /// Picker selection, `.weekly` shows as `.daily` since both are picked with the week days
    private var pickerFrequency: Binding<Habit.Frequency> {
        Binding(
            get: { self.isWeekDaysFrequency ? .daily : self.habit.frequency },
            set: { frequency in
                guard !(frequency == .daily && self.isWeekDaysFrequency) else { return }
                self.habit.frequency = frequency
            }
        )
    }

    /// Week days ordered by the start of the week setting
    private var orderedWeekDays: [WeekDay] {
        let first = self.state.calendar.firstWeekday - 1
        let days = WeekDay.allCases
        return Array(days[first...] + days[..<first])
    }

    private var weekDaysView: some View {
        var calendar = self.state.calendar
        calendar.locale = self.locale
        let symbols = calendar.veryShortStandaloneWeekdaySymbols

        return HStack(spacing: 0) {
            ForEach(self.orderedWeekDays) { day in
                let isSelected = self.habit.repeatWeekDays.contains(day)

                Button {
                    self.habit.toggleWeekDay(day)
                } label: {
                    Text(symbols[day.rawValue - 1])
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? Color.dayProgress : Color.dayTrack, in: .circle)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(day.localizedName(locale: self.locale))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("habit_week_day_\(day.rawValue)")
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: self.habit.repeatWeekDays)
        .disabled(!isEditing)
    }

    @ViewBuilder
    private var weekDaysFooter: some View {
        let days = self.habit.repeatWeekDays

        if days.count == WeekDay.allCases.count {
            Text("habit_frequency_every_day_hint")
        } else if days.isEmpty {
            Text("habit_frequency_no_days")
        } else {
            Text("habit_frequency_every_days \(self.weekDayNames(days))")
        }
    }

    /// Names of `days` in week order, like "Monday, Wednesday, Friday"
    private func weekDayNames(_ days: Set<WeekDay>) -> String {
        return self.orderedWeekDays
            .filter { days.contains($0) }
            .map { $0.localizedName(locale: self.locale) }
            .joined(separator: ", ")
    }

    // MARK: Goal

    /// Goal on starts a times goal of the default value, off removes it. Goals work with every frequency
    private var hasGoal: Binding<Bool> {
        Binding(
            get: { self.habit.goal != nil },
            set: { isOn in
                self.habit.goal = isOn ? Goal(type: .times, value: Goal.defaultValue) : nil
            }
        )
    }

    private var goalValue: Binding<Int> {
        Binding(
            get: { self.habit.goal?.value ?? 0 },
            set: { self.habit.goal?.value = $0 }
        )
    }

    private var goalType: Binding<GoalType> {
        Binding(
            get: { self.habit.goal?.type ?? .times },
            set: { self.habit.goal?.type = $0 }
        )
    }

    private var goalSection: some View {
        Section {
            Toggle("habit_goal", isOn: self.hasGoal)
                .accessibilityIdentifier("habit_goal")
                .disabled(!isEditing)

            if let goal = self.habit.goal {
                HStack {
                    TextField("habit_goal_value", text: self.numberText(self.goalValue))
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("habit_goal_value")

                    // Menu so the icons are only shown in the list, not next to the picked type
                    Menu {
                        Picker("habit_goal_type", selection: self.goalType) {
                            ForEach(GoalType.allCases, id: \.self) { type in
                                Label(type.title, systemImage: type.systemImage).tag(type)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(goal.type.title)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(Color.secondary)
                    }
                    .accessibilityIdentifier("habit_goal_type")
                    .fixedSize()
                }
                .disabled(!isEditing)
            }
        } footer: {
            if let goal = self.habit.goal {
                if goal.value > 0 {
                    Text(goal.type.hint(value: goal.value))
                }
            } else {
                Text("habit_goal_off_hint")
            }
        }
    }
}

private extension GoalType {
    var title: LocalizedStringKey {
        switch self {
        case .times: "habit_goal_times_a_day"
        }
    }

    var systemImage: String {
        switch self {
        case .times: "textformat.123"
        }
    }

    func hint(value: Int) -> LocalizedStringKey {
        switch self {
        case .times: "habit_goal_times_a_day_hint \(value)"
        }
    }
}
