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
            .onChange(of: self.habit.frequency) { frequency in
                if frequency != .weekly {
                    self.habit.frequencyType.weekFrequency.removeAll()
                }
                if frequency != .interval {
                    self.habit.scheduleInterval = nil
                }
            }
            .disabled(!isEditing)

            switch self.habit.frequency {
            case .daily: EmptyView()
            case .weekly:
                Spacer()
                ForEach(WeekDay.allCases, id: \.self) { day in
                    HStack {
                        Text(day.rawValue).tag(day)
                        Spacer()
                        if self.habit.frequencyType.weekFrequency.contains(day) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
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
                    }
                }
            }
        }

        let scheduleValidation: Bool = self.habit.schedule.count > 0 || self.habit.schedule.count == 0 && isEditing
        Section {
            ForEach(self.$habit.schedule) { $hour in
                if let index = self.habit.schedule.firstIndex(of: hour) {
                    let datePicker = DatePicker("Hour #\(index + 1)",
                                                selection: $hour.date,
                                                displayedComponents: .hourAndMinute
                    )

                    datePicker
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
                    let calendar = Calendar.current
                    var date: Date = Date.now
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
                        let scheduleSorted = self.habit.schedule.sorted { (lhs: Habit.Hour, rhs: Habit.Hour) in
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
                        Habit.Hour(eventId: "", date: date)
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
}
