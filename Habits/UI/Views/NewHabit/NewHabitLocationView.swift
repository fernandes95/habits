//
//  NewHabitLocationView.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/09/2024.
//

import SwiftUI

struct NewHabitLocationView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @Binding
    var habit: Habit

    var body: some View {
        VStack {
            Text("new_habit_location_title")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            Form {
                Section(header: Text("new_habit_location_section_title")) {
                    VStack {
                        Text("new_habit_location_info")

                        MapView(location: self.$habit.location, canEdit: .constant(true))
                            .frame(height: 250)
                            .cornerRadius(10)
                    }
                }
            }

            Button("general_continue") {
                Task {
                    try await self.state.getNotificationsAuthorization()
                }
                if !self.habit.hasLocationReminder {
                    self.state.getLocationAuthorization()
                }

                self.router.push(NewHabitResumeView(habit: self.$habit))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(15)
        }
        .padding(.vertical)
    }
}

#Preview {
    NewHabitLocationView(habit: .constant(Habit.empty))
}
