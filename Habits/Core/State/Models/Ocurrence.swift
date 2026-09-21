//
//  Ocurrence.swift
//  Habits
//
//  Created by Tiago Fernandes on 15/03/2024.
//

import Foundation

struct Ocurrence: Codable, Equatable {
    var weekFrequency: [WeekDay] = []
    var minimumTimes: Int = 0
    var minimumDays: Int = 0
}
