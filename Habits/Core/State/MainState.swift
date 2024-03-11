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
        let store: StoreEntity = try await load()
        let habits: [Habit] = store.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .map { habitEntity in
                let habit = Habit(habitEntity: habitEntity, selectedDate: selectedDate)
                return habit
            }
        
        let habitsDaily: [Habit] = habits.filter { $0.frequency == .daily}
        let habitsWeekly: [Habit] = habits
            .filter { $0.frequency == .weekly }
            .compactMap { habit in
                let daysDiff = DateHelper.numberOfDaysBetween(habit.startDate, and: self.selectedDate)
                
                return if (daysDiff % 7) == 0 {
                    habit
                } else {
                    nil
                }
            }
        
        let uncheckedDailyList = habitsDaily
            .filter { !$0.isChecked }
        let uncheckedWeeklyList = habitsWeekly
            .filter { !$0.isChecked }
        
        let uncheckedList = uncheckedDailyList + uncheckedWeeklyList
        
        let checkedDailyList = habitsDaily
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }
        let checkedWeeklyList = habitsWeekly
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }
        
        let checkedList = checkedDailyList + checkedWeeklyList
        
        self.habits = uncheckedList + checkedList
    }
    
    func updateHabit(habit: Habit) async throws {
        do {
            var store: StoreEntity = try await load()
            if let index = store.habits.firstIndex(where: { $0.id == habit.id}) {
                var updatedHabit: HabitEntity = store.habits[index].with(
                    name: habit.name,
                    endDate: habit.endDate,
                    category: habit.category.rawValue,
                    schedule: habit.schedule.map { hour in
                        return HabitEntity.Hour(date: hour.date)
                    }
                )
                
                if let statusIndex = updatedHabit.statusList.firstIndex(where: { $0.date.startOfDay == self.selectedDate.startOfDay }) {
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
                
                updatedHabit.successRate = updatedHabit.getSuccessRate()
                
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
                    eventId: habit.eventId,
                    name: habit.name,
                    startDate: habit.startDate,
                    endDate: habit.endDate,
                    frequency: habit.frequency.rawValue, 
                    category: habit.category.rawValue,
                    schedule: habit.schedule.map { hour in
                        return HabitEntity.Hour(date: hour.date)
                    }
                )
            )
            
            try await storeService.save(store)
            try await loadHabits(date: self.selectedDate)
        } catch { }
    }
}
