//
//  NewHabitNameView.swift
//  Habits
//
//  Created by Tiago Fernandes on 16/09/2024.
//

import SwiftUI

struct NewHabitNameView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @State
    private var habit: Habit = Habit.empty

    var body: some View {
        VStack {
            Text("new_habit_name_title")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("", text: self.$habit.name)
                .font(.title)
                .textFieldStyle(.roundedBorder)

            Spacer()
        }
        .padding(16)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("general_next") {
                    self.router.push(NewHabitDurantionView(habit: self.$habit))
                }
                .disabled(self.habit.name.isEmpty)
            }
        }
    }
}

#Preview {
    NewHabitNameView()
}
