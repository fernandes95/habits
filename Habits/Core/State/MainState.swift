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
    var items: [Item] = []
    
    @Published
    var selectedDate: Date = Date.now
    private let storeService = DefaultStoreService()
    
    private func load() async -> [Habit] {
        return await Task {
            do {
                return try await storeService.load()
            } catch { return [] }
        }.value
    }
    
    func loadHabits(date: Date) {
        Task {
            do {
                self.items = []
                selectedDate = date
                let habits = await load()
                let items: [Item] = habits
                    .filter { ($0.startDate.formatDate() ... $0.endDate.formatDate()).contains(date.formatDate())}
                    .map { habit in
                    
                    var item: Item = Item(
                        id: habit.id,
                        name: habit.name,
                        startDate: habit.startDate,
                        endDate: habit.endDate,
                        isChecked: false
                    )
                    
                    if let status: Habit.Status = habit.statusList.first(where: { $0.date.formatDate() == date.formatDate()}) {
                        item.isChecked = status.isChecked
                    }
                    
                    return item
                }
                
                self.items = items
            }
        }
            
    }
    
//    func saveItem(_ item: Item) {
//        Task {
//            do {
//                let habits = try await storeService.load()
//                
//            } catch { }
//        }
//    }
    
    func addItem(_ item: Item) {
        Task {
            do {
                var habits = await load()
                habits.append(Habit(name: item.name, startDate: item.startDate, endDate: item.endDate))
                
                try await storeService.save(habits)
                loadHabits(date: selectedDate)
                
            } catch { }
        }
    }
}

extension MainState {
    struct Item: Identifiable, Equatable {
        var id: UUID
//        var statusId: UUID
        var name: String
        var startDate: Date
        var endDate: Date
        var isChecked: Bool
    }
}
