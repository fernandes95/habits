//
//  NewHabitScheduleView.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/09/2024.
//

import SwiftUI

struct NewHabitScheduleView: View {
    @Binding var habit: Habit

    var startDateIn: Date = Date.now

    var body: some View {
        VStack {
            Text("Do you want to create a schedule?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            Form {
                Section(header: Text("habit_new_section_habit_frequency")) {
                    Picker("habit_frequency", selection: $habit.frequency) {
                        ForEach(Habit.Frequency.allCases) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                                .onTapGesture {
                                    if frequency != .weekly {
                                        //                                    $habit.weekFrequency.removeAll()
                                        habit.frequencyType.weekFrequency.removeAll()
                                    }
                                }
                        }
                    }

                    let weeklyValidation: Bool = habit.frequency != .weekly
                    Spacer()
                        .isHidden(weeklyValidation)
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        HStack {
                            Text(day.rawValue).tag(day)
                            Spacer()
                            if habit.frequencyType.weekFrequency.contains(day) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if habit.frequencyType.weekFrequency.contains(day) {
                                habit.frequencyType.weekFrequency.removeAll(where: {$0 == day})
                            } else {
                                habit.frequencyType.weekFrequency.append(day)
                            }
                        }
                    }
                    .isHidden(weeklyValidation)
                }

                let scheduleValidation: Bool = habit.schedule.count > 0 || habit.schedule.count == 0
                Section {
                    ForEach($habit.schedule) { $hour in
                        if let index = habit.schedule.firstIndex(of: hour) {
                            let datePicker = DatePicker("Hour #\(index + 1)",
                                                        selection: $hour.date,
                                                        displayedComponents: .hourAndMinute
                            )

                            datePicker
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        habit.schedule.remove(at: index)

                                        if habit.schedule.isEmpty {
                                            habit.hasAlarm = false
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

                            if habit.schedule.isEmpty {
                                var dateComponents = calendar.dateComponents(
                                    [.day, .month, .year, .hour, .minute],
                                    from: habit.startDate
                                )
                                dateComponents.hour = 09
                                dateComponents.minute = 00
                                dateComponents.second = 00

                                mainDateComponents = dateComponents

                                habit.hasAlarm = true
                            } else {
                                let scheduleSorted = habit.schedule.sorted { (lhs: Habit.Hour, rhs: Habit.Hour) in
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

                            habit.schedule.append(
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

            Button("Continue") {

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(15)
        }
        .padding(.vertical)
    }
}

#Preview {
    NewHabitScheduleView(habit: .constant(Habit.empty))
}
