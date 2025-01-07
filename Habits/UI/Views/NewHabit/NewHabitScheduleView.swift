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

    var body: some View {
        VStack {
            Text("new_habit_schedule_title")
                .font(.largeTitle)
                .fontWeight(.bold)
            Form {
                HabitFrequencyView(
                    habit: self.$habit,
                    isEditing: .constant(true)
                )
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
