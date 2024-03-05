//
//  HabitEntity.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import Foundation

struct HabitEntity: Codable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var frequency: Frequency
    var category: Category
    var statusList: [Status]
    var updatedDate: Date
    let createdDate: Date
    
    init(id: UUID = UUID(),
         name: String,
         startDate: Date,
         endDate: Date,
         frequency: String,
         category: String,
         statusList: [Status] = [],
         updatedDate: Date = Date.now
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.frequency = getEntityFrequency(frequency)
        self.category = getEntityCategory(category)
        self.statusList = statusList
        self.updatedDate = updatedDate
        self.createdDate = Date.now
    }
    
    internal func with(
        name: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        frequency: String? = nil,
        category: String? = nil,
        statusList: [Status]? = nil,
        updatedDate: Date? = nil
    ) -> Self {
        return Self(
            id: self.id,
            name: name ?? self.name,
            startDate: self.startDate,
            endDate: endDate ?? self.endDate,
            frequency: frequency ?? self.frequency.rawValue,
            category: category ?? self.category.rawValue,
            statusList: statusList ?? self.statusList,
            updatedDate: updatedDate ?? self.updatedDate
        )
    }
}

extension HabitEntity {
    struct Status: Codable {
        let id: UUID
        let date: Date
        var updatedDate: Date
        var isChecked: Bool
        
        init(id: UUID = UUID(), date: Date, updatedDate: Date = Date.now, isChecked: Bool = false) {
            self.id = id
            self.date = date
            self.updatedDate = updatedDate
            self.isChecked = isChecked
        }
    }
}

func getEntityFrequency(_ frequency: String) -> HabitEntity.Frequency {
    return switch frequency {
        case HabitEntity.Frequency.weekly.rawValue:
            HabitEntity.Frequency.weekly
        case HabitEntity.Frequency.monthly.rawValue:
            HabitEntity.Frequency.monthly
        case HabitEntity.Frequency.yearly.rawValue:
            HabitEntity.Frequency.yearly
        default:
            HabitEntity.Frequency.daily
    }
}

func getEntityCategory(_ category: String) -> HabitEntity.Category {
    return if category == HabitEntity.Category.newHabit.rawValue {
        HabitEntity.Category.newHabit
    } else {
        HabitEntity.Category.badHabit
    }
}

extension HabitEntity {
    enum Frequency: String, Codable {
        case daily
        case weekly
        case monthly
        case yearly
//        case Custom
    }
}

extension HabitEntity {
    enum Category: String, Codable {
        case newHabit
        case badHabit
    }
}
