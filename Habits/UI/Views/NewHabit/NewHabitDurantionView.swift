//
//  NewHabitDurantionView.swift
//  Habits
//
//  Created by Tiago Fernandes on 16/09/2024.
//

import SwiftUI

struct NewHabitDurantionView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @Binding
    var habit: Habit

    var startDateIn: Date = Date.now

    var body: some View {
        VStack {
            Text("new_habit_duration_title")
                .font(.largeTitle)
                .fontWeight(.bold)
            Form {
                Section(header: Text("habit_new_section_habit_info")) {
                    DatePicker("habit_start_date", selection: $habit.startDate,
                               in: self.startDateIn...,
                               displayedComponents: .date
                    )

                    DatePicker("habit_end_date", selection: self.$habit.endDate,
                               in: self.habit.startDate...,
                               displayedComponents: .date)
                }
            }
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("general_next") {
                    self.router.push(NewHabitScheduleView(habit: self.$habit))
                }
            }
        }
    }
}

#Preview {
    NewHabitDurantionView(habit: .constant(Habit.empty))
}
