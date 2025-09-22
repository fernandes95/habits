//
//  HabitNotificationEntity.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/09/2025.
//

import Foundation

struct HabitNotificationEntity: Codable {
    var habitId: UUID
    var date: Date
    
    init(
        habitId: UUID,
        date: Date
    ) {
        self.habitId = habitId
        self.date = date
    }
}
