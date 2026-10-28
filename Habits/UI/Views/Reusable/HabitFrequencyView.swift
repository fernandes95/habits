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
                if frequency != .minTimes {
                    self.habit.frequencyType.minimumTimes = 0
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
            case .minTimes:
                TextField("habit_min_times", text: self.numberText(self.$habit.frequencyType.minimumTimes))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("habit_min_times")
                    .disabled(!isEditing)
            }
        } header: {
            Text("habit_new_section_habit_frequency")
        } footer: {
            if self.habit.frequency == .daily || self.habit.frequency == .weekly {
                self.weekDaysFooter
            }
        }

        let scheduleValidation: Bool = self.habit.schedule.count > 0 || self.habit.schedule.count == 0 && isEditing
        Section {
            ForEach(self.$habit.schedule) { $hour in
                if let index = self.habit.schedule.firstIndex(of: hour) {
                    let datePicker = DatePicker("habit_schedule_hour \(index + 1)",
                                                selection: $hour.date,
                                                displayedComponents: .hourAndMinute
                    )

                    datePicker
                        // On touch down, before the picker opens and remembers the focused field
                        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in self.dismissKeyboard() })
                        .swipeActions(edge: .trailing) {
                            if isEditing {
                                Button(role: .destructive) {
                                    self.habit.schedule.remove(at: index)

                                    if self.habit.schedule.isEmpty {
                                        self.habit.hasAlarm = false
                                    }
                                } label: {
                                    Label("habit_schedule_delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }.disabled(!isEditing)
        } header: {
            HStack {
                Text("habit_new_section_habit_schedule")
                Spacer()
                Button(action: {
                    self.dismissKeyboard()

                    let calendar = Calendar.current
                    var date: Date = .now
                    var mainDateComponents: DateComponents = DateComponents()

                    if self.habit.schedule.isEmpty {
                        var dateComponents = calendar.dateComponents(
                            [.day, .month, .year, .hour, .minute],
                            from: self.habit.startDate
                        )
                        dateComponents.hour = 09
                        dateComponents.minute = 00
                        dateComponents.second = 00

                        mainDateComponents = dateComponents

                        self.habit.hasAlarm = true
                    } else {
                        let scheduleSorted = self.habit.schedule.sorted { (lhs: Hour, rhs: Hour) in
                            return (lhs.date < rhs.date)
                        }
                        if let hour = scheduleSorted.last {
                            var dateComponents = calendar.dateComponents(
                                [.day, .month, .year, .hour, .minute],
                                from: hour.date
                            )
                            dateComponents.hour = (dateComponents.hour ?? 9) + 1
                            dateComponents.minute = dateComponents.minute

                            mainDateComponents = dateComponents
                        }
                    }

                    if let newDate = calendar.date(from: mainDateComponents) {
                        date = newDate
                    }

                    self.habit.schedule.append(
                        Hour(eventId: "", date: date)
                    )
                }, label: {
                    Image(systemName: "plus")
                })
                .isHidden(!isEditing)
                .accessibilityLabel("habits_accessibility_new_schedule_hour")
            }
        }
        .isHidden(!scheduleValidation)
    }

    // MARK: Week days

    /// Picker selection, `.weekly` shows as `.daily` since both are picked with the week days
    private var pickerFrequency: Binding<Habit.Frequency> {
        Binding(
            get: { self.habit.frequency == .weekly ? .daily : self.habit.frequency },
            set: { frequency in
                guard !(frequency == .daily && self.habit.frequency == .weekly) else { return }
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

    /// Removes the focus from any text field. The hour picker gives the focus back to
    /// the last focused field when it closes, so it has to be cleared before it opens.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
