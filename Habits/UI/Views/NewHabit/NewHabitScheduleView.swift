//
//  NewHabitScheduleView.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/09/2024.
//

import SwiftUI

struct NewHabitScheduleView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @Binding
    var habit: Habit

    var startDateIn: Date = Date.now

    var body: some View {
        VStack {
            Text("new_habit_schedule_title")
                .font(.largeTitle)
                .fontWeight(.bold)
            Form {
                Section(header: Text("habit_new_section_habit_frequency")) {
                    Picker("habit_frequency", selection: self.$habit.frequency) {
                        ForEach(Habit.Frequency.allCases) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                                .onTapGesture {
                                    if frequency != .weekly {
                                        self.habit.frequencyType.weekFrequency.removeAll()
                                    }
                                }
                        }
                    }

                    let weeklyValidation: Bool = self.habit.frequency != .weekly
                    Spacer()
                        .isHidden(weeklyValidation)
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
                    .isHidden(weeklyValidation)
                }

                let scheduleValidation: Bool = self.habit.schedule.count > 0 || self.habit.schedule.count == 0
                Section {
                    ForEach(self.$habit.schedule) { $hour in
                        if let index = self.habit.schedule.firstIndex(of: hour) {
                            let datePicker = DatePicker("Hour #\(index + 1)",
                                                        selection: $hour.date,
                                                        displayedComponents: .hourAndMinute
                            )

                            datePicker
                                .swipeActions(edge: .trailing) {
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
                        .accessibilityLabel("habits_accessibility_new_schedule_hour")
                    }
                }
                .isHidden(!scheduleValidation)
            }
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("general_next") {
                    self.router.push(NewHabitLocationView(habit: self.$habit))
                }
            }
        }
    }
}

#Preview {
    NewHabitScheduleView(habit: .constant(Habit.empty))
}
