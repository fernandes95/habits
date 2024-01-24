//
//  AddHabitView.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI

struct NewHabitView: View {
    @Binding var isPresentingNewHabit: Bool
    @Binding var habits: [Habit]
    @State private var newHabit = Habit(name: "", date: Date.now, status: false)
    @State private var startDate = Date.now
    @State private var endDate = Date.now
    @State private var dateInterval = 0
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newHabit.name)
                DatePicker("Start Date", selection: $newHabit.date,
                           in: Date()...,
                           displayedComponents: .date
                )
                DatePicker("End Date", selection: $endDate,
                           in: startDate...,
                           displayedComponents: .date)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        isPresentingNewHabit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        habits.append(newHabit)
                        isPresentingNewHabit = false
                    }
                }
            }
        }
        
    }
}

#Preview {
    NewHabitView(isPresentingNewHabit: .constant(false), habits: .constant(Habit.sampleData))
}
