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
                    if self.habit.schedule.isEmpty {
                        self.router.push(NewHabitLocationView(habit: self.$habit))
                    } else {
                        self.router.push(NewHabitResumeView(habit: self.$habit))
                    }
                }
                .disabled(!self.canContinue())
            }
        }
    }

    private func canContinue() -> Bool {
        switch self.habit.frequency {
        case .daily: return true
        case .interval:
            if let interval = self.habit.scheduleInterval {
                return interval >= 2
            }
            return false
        case .weekly: return !self.habit.frequencyType.weekFrequency.isEmpty
        }
    }
}

#Preview {
    NewHabitScheduleView(habit: .constant(Habit.empty))
}
