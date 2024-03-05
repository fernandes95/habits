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
    var frequency: String
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
        self.frequency = frequency
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
            frequency: self.frequency,
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

func getEntityCategory(_ category: String) -> HabitEntity.Category {
    return if category == HabitEntity.Category.newHabit.rawValue {
        HabitEntity.Category.newHabit
    } else {
        HabitEntity.Category.badHabit
    }
}

extension HabitEntity {
    enum Frequency: String, Identifiable, CaseIterable, Codable {
        case Daily
        case Weekly
        case Monthly
        case Yearly
        case Custom
        
        var id: String {
            rawValue.capitalized
        }
    }
}

extension HabitEntity {
    enum Category: String, Codable {
        case newHabit
        case badHabit
    }
}
