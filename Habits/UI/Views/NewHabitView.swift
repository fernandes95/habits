//
//  AddHabitView.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI
import Foundation

struct NewHabitView: View {
    @EnvironmentObject
    private var store: StoreHabits
    
    @Binding var isPresentingNewHabit: Bool
    private let newHabitGroupId = UUID()
    @State private var newHabit = Habit(groupId: UUID(), name: "", date: Date.now, statusDate: Date.now)
    @State var startDate: Date
    @State private var endDate = Date.now
//    @State private var frequency: HabitFrequency = .Daily
    
    var body: some View {
        NavigationStack {
            NewHabitContentView(
                habitName: $newHabit.name,
                startDate: $startDate,
                endDate: $endDate,
                isEdit: .constant(true),
                isNew: true
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general_dismiss") {
                        isPresentingNewHabit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("general_add") {
                        addHabits()
                    }.disabled(newHabit.name.isEmpty)
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
                let addHabit = Habit(groupId: newHabitGroupId, name: newHabit.name, date: newDate, status: false, statusDate: Date.now)
                
                store.habits.append(addHabit)
            }
        }
        
        Task {
            do {
                try await store.save()
            } catch { }
        }
        
        isPresentingNewHabit = false
    }
}

#Preview {
    NewHabitView(isPresentingNewHabit: .constant(false), startDate: Date.now)
}
