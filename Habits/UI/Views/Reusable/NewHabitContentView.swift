//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI
import MapKit

struct NewHabitContentView: View {
    @EnvironmentObject
    private var state: MainState

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

            HabitFrequencyView(
                habit: self.$habit,
                isEditing: self.$isEdit
            )

//            let isDisabled = $habit.schedule.isEmpty ? true : !isEdit
//            Toggle("habit_has_alarm", isOn: $habit.hasAlarm)
//                .isHidden(!scheduleValidation)
//                .disabled(isDisabled)

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

 #Preview {
     NewHabitContentView(
        habit: .constant(Habit.empty),
        isEdit: .constant(true),
        isNew: true,
        startDateIn: Date.now,
        successRate: nil,
        locationAction: {},
        notificationAction: {}
     )
 }
