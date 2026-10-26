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
        Section(header: Text("habit_new_section_habit_frequency")) {
            Picker("habit_frequency", selection: self.$habit.frequency) {
                ForEach(Habit.Frequency.allCases) { frequency in
                    Text(frequency.rawValue).tag(frequency)
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
            case .daily: EmptyView()
            case .weekly:
                Spacer()
                ForEach(WeekDay.allCases, id: \.self) { day in
                    HStack {
                        Text(day.localizedName).tag(day)
                        Spacer()
                        if self.habit.frequencyType.weekFrequency.contains(day) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("habit_week_day_\(day.rawValue)")
                    .onTapGesture {
                        if self.habit.frequencyType.weekFrequency.contains(day) {
                            self.habit.frequencyType.weekFrequency.removeAll(where: {$0 == day})
                        } else {
                            self.habit.frequencyType.weekFrequency.append(day)
                        }
                    }
                }
                .disabled(!isEditing)

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
