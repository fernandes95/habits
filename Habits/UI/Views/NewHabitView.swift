//
//  AddHabitView.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI
import Foundation
import EventKitUI

struct NewHabitView: View {
    @EnvironmentObject
    private var state: MainState

    @Binding var isPresentingNewHabit: Bool

    @State var startDate: Date
    @State private var habit: Habit = Habit(
        id: UUID(), eventId: "", name: "", startDate: Date.now, endDate: Date.now,
        frequency: Habit.Frequency.daily.rawValue, frequencyType: Ocurrence(weekFrequency: []),
        category: Habit.Category.new.rawValue, schedule: [], isChecked: false,
        hasAlarm: false, successRate: "0", createdDate: Date.now, updatedDate: Date.now)

    var body: some View {
        NavigationStack {
            NewHabitContentView(
                habit: $habit,
                isEdit: .constant(true),
                isNew: true,
                startDateIn: state.selectedDate,
                locationAction: {
                    Task {
                        state.getLocationAuthorization()
                    }
                },
                notificationAction: {
                    Task {
                        try await state.getNotificationsAuthorization()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general_dismiss") {
                        isPresentingNewHabit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("general_add") {
                        addHabit()
                    }.disabled(habit.name.isEmpty)
                }
            }
        }
        .onAppear {
            habit.startDate = startDate
            habit.endDate = startDate
        }
    }

    private func addHabit() {
        Task {
            if habit.startDate >= habit.endDate {
                habit.endDate = habit.startDate
            }
            let newHabit = self.habit
            // FIXME:
//            newHabit.createdDate = Date.now
//            newHabit.updatedDate = Date.now

            try await state.addHabit(newHabit)

            isPresentingNewHabit = false
        }
    }
}
//
// #Preview {
//    NewHabitView(isPresentingNewHabit: .constant(false), startDate: Date.now)
// }
