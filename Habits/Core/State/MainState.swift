//
//  MainState.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation
import SwiftUI

@MainActor
class MainState: ObservableObject {
    
    @Published
    var habits: [Habit] = []
    
    @Published
    var selectedDate: Date = Date.now
    private let storeService = DefaultStoreService()
    
    private func load() async throws -> StoreEntity {
        return try await storeService.load()
    }
    
    func loadHabits(date: Date) async throws {
        self.habits = []
        self.selectedDate = date
        let store : StoreEntity = try await load()
        let habits: [Habit] = store.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .map { habitEntity in
            
            var habit = Habit(
                id: habitEntity.id,
                name: habitEntity.name,
                startDate: habitEntity.startDate,
                endDate: habitEntity.endDate,
                frequency: habitEntity.frequency, 
                category: habitEntity.category.rawValue,
                isChecked: false,
                createdDate: habitEntity.createdDate,
                updatedDate: date
            )
            
            if let status: HabitEntity.Status = habitEntity.statusList.first(
                where: { $0.date.formatDate() == date.formatDate()}
            ) {
                habit.isChecked = status.isChecked
                habit.updatedDate = status.updatedDate
            }
            
            return habit
        }
        
        let uncheckedList = habits
            .filter { !$0.isChecked }
                  
        let checkedList = habits
            .filter { $0.isChecked }
            .sorted { (lhs: Habit, rhs: Habit) in
                return (lhs.updatedDate < rhs.updatedDate)
            }
        
        self.habits = uncheckedList + checkedList
    }
    
    func updateHabit(habit: Habit) async throws {
        do {
            var store: StoreEntity = try await load()
            if let index = store.habits.firstIndex(where: { $0.id == habit.id}) {
                var updatedHabit: HabitEntity = store.habits[index].with(
                    name: habit.name,
                    endDate: habit.endDate,
                    category: habit.category.rawValue
                )
                
                if let statusIndex = updatedHabit.statusList.firstIndex(where: { $0.date == self.selectedDate }) {
                    var status = updatedHabit.statusList[statusIndex]
                    status.isChecked = habit.isChecked
                    status.updatedDate = Date.now
                    
                    updatedHabit.statusList[statusIndex] = status
                } else {
                    let status = HabitEntity.Status(
                        date: self.selectedDate,
                        isChecked: habit.isChecked
                    )
                    updatedHabit.statusList.append(status)
                }
                
                store.habits[index] = updatedHabit
            }
            
            try await storeService.save(store)
            try await loadHabits(date: self.selectedDate)
        } catch {}
    }
    
    func removeHabit(habitId: UUID) async throws {
        do {
            var store: StoreEntity = try await load()
            if let index = store.habits.firstIndex(where: { $0.id == habitId }) {
                let deleteHabit = store.habits[index]
                
                store.habitsArchived.append(deleteHabit)
                store.habits.remove(at: index)
                
                try await storeService.save(store)
                try await loadHabits(date: self.selectedDate)
            }
        } catch {}
    }
    
    func addHabit(_ habit: Habit) async throws {
        do {
            var store: StoreEntity = try await load()
            store.habits.append(
                HabitEntity(
                    name: habit.name,
                    startDate: habit.startDate,
                    endDate: habit.endDate,
                    frequency: HabitEntity.Frequency.Daily.rawValue, 
                    category: habit.category.rawValue
                )
            )
            
            try await storeService.save(store)
            try await loadHabits(date: self.selectedDate)
        } catch { }
    }
}
