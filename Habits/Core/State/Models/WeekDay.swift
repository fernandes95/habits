//
//  WeekDay.swift
//  Habits
//
//  Created by Tiago Fernandes on 18/03/2024.
//

import Foundation
import EventKit

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

func getWeekDay(ekWeekday: EKWeekday) -> WeekDay {
    return switch ekWeekday {
            case .monday:
                WeekDay.monday
            case .tuesday:
                WeekDay.tuesday
            case .wednesday:
                WeekDay.wednesday
            case .thursday:
                WeekDay.thursday
            case .friday:
                WeekDay.friday
            case .saturday:
                WeekDay.saturday
            default:
                WeekDay.sunday
            }
}
