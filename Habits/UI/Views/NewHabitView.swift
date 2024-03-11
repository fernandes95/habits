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
    
    var store = EKEventStore()
    
    @Binding var isPresentingNewHabit: Bool
    @State private var name: String = ""
    @State var startDate: Date
    @State private var endDate: Date = Date.now
    @State private var frequency: Habit.Frequency = .daily
    @State private var category: Habit.Category = .new
    @State private var schedule: [Habit.Hour] = []
    
    var body: some View {
        NavigationStack {
            NewHabitContentView(
                name: $name,
                startDate: $startDate,
                endDate: $endDate, 
                frequency: $frequency,
                category: $category, 
                schedule: $schedule,
                isEdit: .constant(true),
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
        .onAppear() {
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
                name: name,
                startDate: startDate,
                endDate: endDate, 
                frequency: frequency.rawValue, 
                category: category.rawValue, 
                schedule: schedule,
                isChecked: false,
                successRate: "0",
                createdDate: Date.now,
                updatedDate: Date.now
            )
            try await state.addHabit(newHabit)
            
            isPresentingNewHabit = false
        }
    }
}

#Preview {
    NewHabitView(isPresentingNewHabit: .constant(false), startDate: Date.now)
}
