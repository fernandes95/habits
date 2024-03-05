//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 27/02/2024.
//

import Foundation

struct Habit: Identifiable, Equatable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var frequency: String
    var category: Category
    var isChecked: Bool
    let createdDate: Date
    var updatedDate: Date
    
    init(id: UUID, name: String, startDate: Date, endDate: Date, frequency: String, category: String, isChecked: Bool, createdDate: Date, updatedDate: Date) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.frequency = frequency
        self.category = getCategory(category)
        self.isChecked = isChecked
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }
}

extension Habit {
    enum Category: String, Identifiable, CaseIterable {
        case newHabit
        case badHabit
        
        var id: String {
            rawValue.capitalized
        }
    }
}

func getCategory(_ category: String) -> Habit.Category {
    return if category == Habit.Category.newHabit.rawValue {
        Habit.Category.newHabit
    } else {
        Habit.Category.badHabit
    }
}

func getCategoryName(_ category: Habit.Category) -> String {
    return if category == .newHabit {
        "New habit"
    } else {
        "Bad habit"
    }
}
