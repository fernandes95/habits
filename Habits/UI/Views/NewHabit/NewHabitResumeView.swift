//
//  NewHabitResumeView.swift
//  Habits
//
//  Created by Tiago Fernandes on 11/10/2024.
//

import SwiftUI

struct NewHabitResumeView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @Binding
    var habit: Habit

    var body: some View {
        VStack {
            Form {
                Section(header: Text("habit_name")) {
                    Text(self.habit.name)
                }

                Section(header: Text("new_habit_resume_duration_section_title")) {
                    DatePicker("habit_start_date", selection: $habit.startDate,
                               in: Date.now...,
                               displayedComponents: .date
                    )
                    .disabled(true)

                    DatePicker("habit_end_date", selection: $habit.endDate,
                               in: habit.startDate...,
                               displayedComponents: .date)
                    .disabled(true)
                }

                Section(header: Text("habit_new_section_habit_frequency")) {
                    Picker("habit_frequency", selection: $habit.frequency) {
                        ForEach(Habit.Frequency.allCases) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .disabled(true)

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
                    }
                    .isHidden(weeklyValidation)
                    .disabled(true)
                }

                if self.habit.schedule.count > 0 {
                    Section(header: Text("new_habit_resume_schedule_section_title")) {
                        ForEach(self.habit.schedule) { hour in
                            if let index = self.habit.schedule.firstIndex(of: hour) {
                                DatePicker("Hour #\(index + 1)",
                                           selection: .constant(hour.date),
                                           displayedComponents: .hourAndMinute
                                )
                            }
                        }
                        .disabled(true)
                    }
                }

                if let location = self.habit.location {
                    Section(header: Text("new_habit_resume_location_section_title")) {
                        MapView(location: .constant(location), canEdit: .constant(false))
                            .frame(height: 250)
                            .cornerRadius(10)
                            .disabled(true)
                    }
                }
            }

            Spacer()

            Button("new_habit_resume_button") {
                self.addHabit()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(15)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("general_cancel") {
                    self.router.popToRoot()
                }
            }
        }
    }

    private func addHabit() {
        Task {
            if self.habit.startDate >= self.habit.endDate {
                self.habit.endDate = self.habit.startDate
            }
            let newHabit = self.habit
                .with(
                    createdDate: Date.now,
                    updatedDate: Date.now
                )

            try await self.state.addHabit(newHabit)

            self.router.popToRoot()
        }
    }
}

#Preview {
    NewHabitResumeView(habit: .constant(Habit.empty.with(name: "Cenas")))
}
