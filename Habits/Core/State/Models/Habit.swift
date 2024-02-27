//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 27/02/2024.
//

import Foundation

struct Habit: Identifiable, Equatable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var isChecked: Bool
    var isDeleted: Bool
    var updatedDate: Date
}
