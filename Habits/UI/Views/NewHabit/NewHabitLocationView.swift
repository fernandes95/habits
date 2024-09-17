//
//  NewHabitLocationView.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/09/2024.
//

import SwiftUI

struct NewHabitLocationView: View {
    @EnvironmentObject
    private var state: MainState

    @Binding var habit: Habit

    @State private var notificationAuth: Bool = false

    var body: some View {
        VStack {
            Text("Do you want to get reminders based on your location?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            Form {
                Section(header: Text("Location Reminder")) {
                    VStack {
                        Toggle("hasLocationReminder", isOn: $habit.hasLocationReminder)
                            .onTapGesture {
                                if !habit.hasLocationReminder {
                                    state.getLocationAuthorization()
                                }
                            }

                        Toggle("notificationAuth", isOn: $notificationAuth)
//                            .isHidden(!habit.hasLocationReminder)
                            .onTapGesture {
                                Task {
                                    try await state.getNotificationsAuthorization()
                                }
                            }

                        MapView(location: $habit.location, canEdit: .constant(true))
                            .frame(height: 250)
                            .cornerRadius(10)
//                            .isHidden(!habit.hasLocationReminder)
                    }
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
    NewHabitLocationView(habit: .constant(Habit.empty))
}
