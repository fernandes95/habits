//
//  NewHabitNameView.swift
//  Habits
//
//  Created by Tiago Fernandes on 16/09/2024.
//

import SwiftUI

struct NewHabitNameView: View {
    @Binding var habit: Habit

    var body: some View {
        VStack {
            Text("What habit do you want to start?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            TextField("", text: self.$habit.name)
                .font(.title)
                .textFieldStyle(.roundedBorder)

            Spacer()

            Button("Continue") {

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(15)
        }
        .padding(16)
    }
}

#Preview {
    NewHabitNameView(habit: .constant(Habit.empty))
}
