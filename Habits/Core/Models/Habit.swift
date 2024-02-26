//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import Foundation

struct Habit: Encodable, Decodable {
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

extension Habit {
    struct Status: Encodable, Decodable {
        let id: UUID
        let date: Date
        let updatedDate: Date
        var isChecked: Bool
        
        init(id: UUID, date: Date, updatedDate: Date, isChecked: Bool = false) {
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
