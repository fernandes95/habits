//
//  WeekDay.swift
//  Habits
//
//  Created by Tiago Fernandes on 18/03/2024.
//

import Foundation
import EventKit

enum WeekDay: Int, Identifiable, CaseIterable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    init(date: Date, calendar: Calendar = .current) {
        self = WeekDay(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
    }

    var ekWeekday: EKWeekday { EKWeekday(rawValue: rawValue) ?? .sunday }

    var localizedName: String { Calendar.current.standaloneWeekdaySymbols[rawValue - 1] }
}
