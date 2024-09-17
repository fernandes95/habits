//
//  NewHabitDurantionView.swift
//  Habits
//
//  Created by Tiago Fernandes on 16/09/2024.
//

import SwiftUI

struct NewHabitDurantionView: View {
    @Binding var habit: Habit

    var startDateIn: Date = Date.now

    var body: some View {
        VStack {
            Text("How long do you want this habit to be?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            Form {
                Section(header: Text("habit_new_section_habit_info")) {
                    DatePicker("habit_start_date", selection: $habit.startDate,
                               in: startDateIn...,
                               displayedComponents: .date
                    )

                    DatePicker("habit_end_date", selection: $habit.endDate,
                               in: habit.startDate...,
                               displayedComponents: .date)
                }
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
    NewHabitDurantionView(habit: .constant(Habit.empty))
}
