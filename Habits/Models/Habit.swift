//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import Foundation

struct Habit: Identifiable, Encodable, Decodable, Equatable {
    let id: UUID
    let groupId: UUID
    var name: String
    var date: Date
    var status: Bool
    var statusDate: Date
    
    init(id: UUID = UUID(), groupId: UUID, name: String, date: Date, status: Bool = false, statusDate: Date) {
        self.id = id
        self.groupId = groupId
        self.name = name
        self.date = date
        self.status = status
        self.statusDate = statusDate
    }
}

extension Habit {
    static let sampleData: [Habit] =
    [
        Habit(groupId: UUID(), name: "Drink Milk", date: Date(), statusDate: Date.now),
        Habit(groupId: UUID(), name: "Take Supplemets", date: Date(), status: true, statusDate: Date.now),
        Habit(groupId: UUID(), name: "Go for a walk", date: Date(), statusDate: Date.now)
    ]
}

enum HabitFrequency: String, Identifiable, CaseIterable {
    case Daily
    case Weekly
    case Monthly
    case Yearly
    case Custom
    
    var id: String {
        rawValue.capitalized
    }
}
