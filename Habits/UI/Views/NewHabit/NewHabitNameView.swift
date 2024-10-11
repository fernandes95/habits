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
                .padding(.top)

            TextField("", text: self.$habit.name)
                .font(.title)
                .textFieldStyle(.roundedBorder)

            Spacer()

            Button("general_continue") {
                self.router.push(NewHabitDurantionView(habit: self.$habit))
            }
            .disabled(self.habit.name.isEmpty)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(15)
        }
        .padding(16)
    }
}

#Preview {
    NewHabitNameView()
}
