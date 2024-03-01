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
    var updatedDate: Date
    let createdDate: Date
    
    init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date, statusList: [Status] = [], updatedDate: Date = Date.now) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.statusList = statusList
        self.updatedDate = updatedDate
        self.createdDate = Date.now
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
