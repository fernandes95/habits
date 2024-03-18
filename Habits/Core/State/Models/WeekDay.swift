//
//  WeekDay.swift
//  Habits
//
//  Created by Tiago Fernandes on 18/03/2024.
//

import Foundation

enum WeekDay: String, Identifiable, CaseIterable, Codable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"

    var id: String {
        rawValue.capitalized
    }
}
