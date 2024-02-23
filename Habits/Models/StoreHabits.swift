//
//  StoreHabits.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI

@MainActor
class StoreHabits: ObservableObject {
    @Published var habits: [Habit] = [] 
    {
        didSet {
            filterListByDate(date: selectedDate)
        }
    }
    
    @Published var filteredHabits: [Habit] = []
    @Published var selectedDate: Date = Date.now
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("habits.data")
    }
    
    func filterListByDate(date: Date) {
        selectedDate = date
        
        let dateList = habits
            .filter { $0.date.formatDate() == date.formatDate() }
        let uncheckedList = dateList
            .filter { !$0.status }
            .sorted { (lhs: Habit, rhs: Habit) in
                return lhs.date < rhs.date
            }
        let checkedList = dateList
            .filter { $0.status }
            .sorted { (lhs: Habit, rhs: Habit) in
                return lhs.statusDate > rhs.statusDate
            }
        
        filteredHabits = uncheckedList + checkedList
    }
    
    func changeHabitStatus(habitId: UUID) {
        if let index = habits.firstIndex(where: {$0.id == habitId}) {
            var habitUpdated = habits[index]
            habitUpdated.status = !habitUpdated.status
            habitUpdated.statusDate = Date.now
            
            habits[index] = habitUpdated
            
            filterListByDate(date: habitUpdated.date)
        }
    }
    
    private func load() async throws {
        let task = Task<[Habit], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let decodedHabits = try JSONDecoder().decode([Habit].self, from: data)
            return decodedHabits
        }
        let habits = try await task.value
        self.habits = habits
        filteredHabits = habits.filter { $0.date.formatDate() == Date.now.formatDate() }
    }
    
    private func save() async throws {
        let task = Task {
            let data = try JSONEncoder().encode(habits)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveData()
    }
    
    func updateHabit(habitId: UUID, habitEdited: Habit) {
        if let index = habits.firstIndex(where: {$0.id == habitId}) {
            habits[index] = habitEdited
            saveData()
        }
    }
    
    func removeHabit(_ habitId: UUID) {
        if let index = habits.firstIndex(where: {$0.id == habitId}) {
            habits.remove(at: index)
            saveData()
        }
    }
    
    func loadData() {
        Task {
            do {
                try await load()
            } catch { }
        }
    }
    
    func saveData() {
        Task {
            do {
                try await save()
            } catch { }
        }
    }
}

