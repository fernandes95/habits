//
//  AddHabitView.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI
import Foundation

struct NewHabitView: View {
    @Binding var isPresentingNewHabit: Bool
    @Binding var habits: [Habit]
    private let newHabitGroupId = UUID()
    @State private var newHabit = Habit(groupId: UUID(), name: "", date: Date.now, statusDate: Date.now)
    @State private var startDate = Date.now
    @State private var endDate = Date.now
//    @State private var frequency: HabitFrequency = .Daily
    var updateList: ()->Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newHabit.name)
                
                DatePicker("Start Date", selection: $startDate,
                           in: Date()...,
                           displayedComponents: .date
                )
                DatePicker("End Date", selection: $endDate,
                           in: startDate...,
                           displayedComponents: .date)
                
//                if startDate.formatDate() != endDate.formatDate() {
//                    Picker("Frequency", selection: $frequency, content: {
//                        ForEach(HabitFrequency.allCases) { frequency in
//                            Text(frequency.rawValue.capitalized).tag(frequency)
//                        }
//                    }).pickerStyle(.menu)
//                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        isPresentingNewHabit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addHabits()
                    }
                }
            }
        }
    }
    
    private func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let calendar = Calendar.current
        let fromDate = calendar.startOfDay(for: from)
        let toDate = calendar.startOfDay(for: to)
        let numberOfDays = calendar.dateComponents([.day], from: fromDate, to: toDate).day
        
        return numberOfDays!
    }
    
    private func addHabits() {
        if startDate >= endDate {
            endDate = startDate
        }
        
        let daysCount = numberOfDaysBetween(startDate, and: endDate)
        
        for i in 0...daysCount {
            var dateComponent = DateComponents()
            dateComponent.day = i
            if let newDate = Calendar.current.date(byAdding: dateComponent, to: startDate) {
                var addHabit = Habit(groupId: newHabitGroupId, name: newHabit.name, date: newDate, status: false, statusDate: Date.now)
                
                habits.append(addHabit)
            }
        }
        
        updateList()
        isPresentingNewHabit = false
    }
}

#Preview {
    NewHabitView(isPresentingNewHabit: .constant(false), habits: .constant(Habit.sampleData), updateList: {})
}
