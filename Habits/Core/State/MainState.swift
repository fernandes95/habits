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
    var items: [Habit] = []
    
    @Published
    var selectedDate: Date = Date.now
    private let storeService = DefaultStoreService()
    
    private func load() async throws -> [HabitEntity] {
        return try await storeService.load()
    }
    
    func loadHabits(date: Date) async throws {
        self.items = []
        selectedDate = date
        let habits = try await load()
        let items: [Habit] = habits
            .filter { ($0.startDate.formatDate() ... $0.endDate.formatDate()).contains(date.formatDate())}
            .map { habit in
            
            var item = Habit(
                id: habit.id,
                name: habit.name,
                startDate: habit.startDate,
                endDate: habit.endDate,
                isChecked: false,
                isDeleted: false,
                updatedDate: date
            )
            
            if let status: HabitEntity.Status = habit.statusList.first(where: { $0.date.formatDate() == date.formatDate()}) {
                item.isChecked = status.isChecked
                item.isDeleted = status.isDeleted
                item.updatedDate = status.updatedDate
            }
            
            return item
        }
            .filter { $0.isDeleted == false }
        
        let uncheckedList = items
            .filter { !$0.isChecked }
                  
        let checkedList = items
            .filter { $0.isChecked }
            .sorted { (lhs: Habit, rhs: Habit) in
                return (lhs.updatedDate < rhs.updatedDate)
            }
        
        self.items = uncheckedList + checkedList
    }
    
    func updateHabit(habit: Habit) async throws {
        do {
            var habits = try await load()
            if let index = habits.firstIndex(where: { $0.id == habit.id}) {
                var habitEntity = habits[index]
                var habitStatus : HabitEntity.Status
                habitEntity.name = habit.name
                habitEntity.endDate = habit.endDate
                
                //TODO: START AND END DATES LOGIC
                
                if let statusIndex = habitEntity.statusList.firstIndex(where: { $0.date == selectedDate }) {
                    habitStatus = habitEntity.statusList[statusIndex]
                    habitStatus.isChecked = !habitStatus.isChecked
                    habitStatus.isDeleted = !habitStatus.isDeleted
                    habitStatus.updatedDate = Date.now
                    
                    habitEntity.statusList[statusIndex] = habitStatus
                } else {
                    habitStatus = HabitEntity.Status(
                        date: selectedDate,
                        isChecked: habit.isChecked,
                        isDeleted: habit.isDeleted
                    )
                    habitEntity.statusList.append(habitStatus)
                }
                
                habits[index] = habitEntity
            }
            
            try await storeService.save(habits)
            try await loadHabits(date: selectedDate)
        } catch {}
    }
    
    func removeHabit(habitId: UUID) async throws {
        do {
            var habits = try await load()
            if let index = habits.firstIndex(where: { $0.id == habitId }) {
                habits.remove(at: index)
                
                try await storeService.save(habits)
                try await loadHabits(date: selectedDate)
            }
            
            
        } catch {}
    }
    
    func addItem(_ item: Habit) async throws {
        do {
            var habits = try await load()
            habits.append(HabitEntity(name: item.name, startDate: item.startDate, endDate: item.endDate))
            
            try await storeService.save(habits)
            try await loadHabits(date: selectedDate)
        } catch { }
    }
}
