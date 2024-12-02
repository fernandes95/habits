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
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("general_next") {
                    Task {
                        try await self.state.getNotificationsAuthorization()
                    }
                    if !self.habit.hasLocationReminder {
                        self.state.getLocationAuthorization()
                    }

                    self.router.push(NewHabitResumeView(habit: self.$habit))
                }
            }
        }
    }
}

#Preview {
    NewHabitLocationView(habit: .constant(Habit.empty))
}
