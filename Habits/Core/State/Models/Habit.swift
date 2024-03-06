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
    var frequency: Frequency
    var category: Category
    var isChecked: Bool
    var successRate: String
    let createdDate: Date
    var updatedDate: Date
    
    init(id: UUID, name: String, startDate: Date, endDate: Date, frequency: String, category: String, isChecked: Bool, successRate: String, createdDate: Date, updatedDate: Date) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.frequency = getFrequency(frequency)
        self.category = getCategory(category)
        self.isChecked = isChecked
        self.successRate = successRate
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }
    
    init(habitEntity: HabitEntity, selectedDate: Date) {
        self.id = habitEntity.id
        self.name = habitEntity.name
        self.startDate = habitEntity.startDate
        self.endDate = habitEntity.endDate
        self.frequency = getFrequency(habitEntity.frequency)
        self.category = getCategory(habitEntity.category)
        self.isChecked = false
        self.successRate = "\(habitEntity.successRate)%"
        self.createdDate = habitEntity.createdDate
        self.updatedDate = habitEntity.updatedDate
        
        if let status: HabitEntity.Status = habitEntity.statusList.first(
            where: { $0.date.formatDate() == selectedDate.formatDate()}
        ) {
            self.isChecked = status.isChecked
            self.updatedDate = status.updatedDate
        }
    }

    enum Category: String, Identifiable, CaseIterable {
        case newHabit
        case badHabit
        
        var id: String {
            rawValue.capitalized
        }
    }
    
    enum Frequency: String, Identifiable, CaseIterable {
        case daily
        case weekly
        case monthly
        case yearly
//        case Custom
        
        var id: String {
            rawValue.capitalized
        }
    }
}

func getFrequency(_ frequency: String) -> Habit.Frequency {
    return switch frequency {
    case Habit.Frequency.weekly.rawValue:
        Habit.Frequency.weekly
    case Habit.Frequency.monthly.rawValue:
        Habit.Frequency.monthly
    case Habit.Frequency.monthly.rawValue:
        Habit.Frequency.yearly
    default:
        Habit.Frequency.daily
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
