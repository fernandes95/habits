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

    var store: EKEventStore = EKEventStore()

    @Binding var isPresentingNewHabit: Bool
    @State private var name: String = ""
    @State var startDate: Date
    @State private var endDate: Date = Date.now
    @State private var frequency: Habit.Frequency = .daily
    @State private var weekFrequency: [WeekDay] = []
    @State private var category: Habit.Category = .new
    @State private var schedule: [Habit.Hour] = []
    @State private var hasAlarm: Bool = false
    @State private var hasLocationReminder: Bool = false
    @State private var location: Habit.Location?

    var body: some View {
        NavigationStack {
            NewHabitContentView(
                name: $name,
                startDate: $startDate,
                endDate: $endDate,
                frequency: $frequency,
                weekFrequency: $weekFrequency,
                category: $category,
                schedule: $schedule,
                isEdit: .constant(true),
                hasAlarm: $hasAlarm,
                hasLocationReminder: $hasLocationReminder,
                location: $location,
                isNew: true,
                startDateIn: state.selectedDate
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
                    }.disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            endDate = startDate
        }
    }

    private func addHabit() {
        Task {
            if startDate >= endDate {
                endDate = startDate
            }
            let newHabit = Habit(
                id: UUID(),
                eventId: "",
                name: self.name,
                startDate: self.startDate,
                endDate: self.endDate,
                frequency: self.frequency.rawValue,
                frequencyType: Ocurrence(weekFrequency: self.weekFrequency),
                category: self.category.rawValue,
                schedule: self.schedule,
                isChecked: false,
                hasAlarm: self.hasAlarm,
                successRate: "0",
                createdDate: Date.now,
                updatedDate: Date.now,
                hasLocationReminder: self.hasLocationReminder,
                location: self.location
            )
            try await state.addHabit(newHabit)

            isPresentingNewHabit = false
        }
    }
}

#Preview {
    NewHabitView(isPresentingNewHabit: .constant(false), startDate: Date.now)
}
