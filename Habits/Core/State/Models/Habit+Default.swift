//
//  Habit+Default.swift
//  Habits
//
//  Created by Tiago Fernandes on 13/05/2024.
//

import Foundation

extension Habit {
    static var empty: Self {
        return Habit(
            id: UUID(),
            eventId: "",
            name: "",
            startDate: Date.now,
            endDate: Date.now,
            frequency: Habit.Frequency.daily.rawValue,
            frequencyType: Ocurrence(weekFrequency: []),
            category: Habit.Category.new.rawValue,
            schedule: [],
            isChecked: false,
            hasAlarm: false,
            successRate: "0",
            createdDate: Date.now,
            updatedDate: Date.now
        )
    }
}
