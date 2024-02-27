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
    var statusList: [Status]
    
    init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date, statusList: [Status] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.statusList = statusList
    }
}

extension HabitEntity {
    struct Status: Codable {
        let id: UUID
        let date: Date
        var updatedDate: Date
        var isChecked: Bool
        var isDeleted: Bool
        
        init(id: UUID = UUID(), date: Date, updatedDate: Date = Date.now, isChecked: Bool = false, isDeleted: Bool = false) {
            self.id = id
            self.date = date
            self.updatedDate = updatedDate
            self.isChecked = isChecked
            self.isDeleted = isDeleted
        }
    }
}

//enum HabitFrequency: String, Identifiable, CaseIterable {
//    case Daily
//    case Weekly
//    case Monthly
//    case Yearly
//    case Custom
//    
//    var id: String {
//        rawValue.capitalized
//    }
//}
