//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI
import MapKit

struct NewHabitContentView: View {
    @Binding var habit: Habit
    @Binding var isEdit: Bool

    let isNew: Bool
    var startDateIn: Date = Date.now
    var successRate: String?
    let locationAction: () -> Void
    let notificationAction: () -> Void

    @State private var hoursDate: Date = Date.now
    @State private var notificationAuth: Bool = false

    var body: some View {
        Form {
            Section(header: Text("habit_new_section_habit_info")) {
                TextField("habit_name", text: $habit.name)
                    .disabled(!isEdit)

                Picker("habit_category", selection: $habit.category) {
                    ForEach(Habit.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .disabled(!isEdit)

                DatePicker("habit_start_date", selection: $habit.startDate,
                           in: startDateIn...,
                           displayedComponents: .date
                )
                .disabled(!isNew)

                DatePicker("habit_end_date", selection: $habit.endDate,
                           in: habit.startDate...,
                           displayedComponents: .date)
                .disabled(!isEdit)
            }

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
                .disabled(!isEdit)

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
                .disabled(!isEdit)
            }

            let scheduleValidation: Bool = habit.schedule.count > 0 || habit.schedule.count == 0 && isEdit
            Section {
                ForEach($habit.schedule) { $hour in
                    if let index = habit.schedule.firstIndex(of: hour) {
                        let datePicker = DatePicker("Hour #\(index + 1)",
                                                    selection: $hour.date,
                                                    displayedComponents: .hourAndMinute
                        )

                        if !isEdit {
                            datePicker
                        } else {
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
                }
                .disabled(!isEdit)
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
                    .isHidden(!isEdit)
                    .accessibilityLabel("habits_accessibility_new_schedule_hour")
                }
            }
            .isHidden(!scheduleValidation)

            let isDisabled = $habit.schedule.isEmpty ? true : !isEdit
            Toggle("habit_has_alarm", isOn: $habit.hasAlarm)
                .isHidden(!scheduleValidation)
                .disabled(isDisabled)

            Section(header: Text("Location Reminder")) {
                VStack {
                    Toggle("hasLocationReminder", isOn: $habit.hasLocationReminder)
                        .disabled(!isEdit)
                        .onTapGesture {
                            if !habit.hasLocationReminder {
                                locationAction()
                            }
                        }

                    Toggle("notificationAuth", isOn: $notificationAuth)
                        .isHidden(!habit.hasLocationReminder)
                        .onTapGesture {
                            notificationAction()
                        }

                    MapView(location: $habit.location, canEdit: $isEdit)
                        .frame(height: 250)
                        .cornerRadius(10)
                        .isHidden(!habit.hasLocationReminder)
                        .disabled(!isEdit)
                }
            }

            Text(successRate ?? "")
                .isHidden(!(!isNew && successRate != nil))
                .disabled(true)
        }
    }
}

// #Preview {
//    NewHabitContentView(
//        
//        name: .constant("cenas"),
//        startDate: .constant(Date.now),
//        endDate: .constant(Date.now),
//        frequency: .constant(.daily),
//        weekFrequency: .constant([]),
//        category: .constant(.new),
//        schedule: .constant([]),
//        isEdit: .constant(true),
//        hasAlarm: .constant(false),
//        hasLocationReminder: .constant(false),
//        location: .constant(nil),
//        isNew: true,
//        successRate: "70%",
//        locationAction: {},
//        notificationAction: {}
//    )
// }
