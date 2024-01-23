//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import Foundation

struct Habit: Identifiable {
    let id: UUID
    var name: String
    var date: Date
    var status: Bool
    
    init(id: UUID = UUID(), name: String, date: Date, status: Bool) {
        self.id = id
        self.name = name
        self.date = date
        self.status = status
    }
}

extension Habit {
    static let sampleData: [Habit] =
    [
        Habit(name: "Drink Milk", date: Date(), status: false),
        Habit(name: "Take Supplemets", date: Date(), status: true),
        Habit(name: "Go for a walk", date: Date(), status: false)
    ]
}
