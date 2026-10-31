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
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .year, value: 100, to: .now)!,
            hasNoEndDate: true,
            frequency: Habit.Frequency.daily.rawValue,
            frequencyType: Ocurrence(weekFrequency: []),
            completedCount: 0,
            category: Habit.Category.new.rawValue,
            schedule: [],
            isChecked: false,
            history: [],
            hasAlarm: false,
            createdDate: .now,
            updatedDate: .now
        )
    }
}
