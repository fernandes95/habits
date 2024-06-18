//
//  StoreEntity.swift
//  Habits
//
//  Created by Tiago Fernandes on 04/03/2024.
//

import Foundation

struct StoreEntity: Codable {
    var habits: [HabitEntity]
    var habitsArchived: [HabitEntity]
}
