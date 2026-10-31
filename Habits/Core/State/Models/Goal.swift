//
//  Goal.swift
//  Habits
//
//  Created by Tiago Fernandes on 28/10/2026.
//

import Foundation

/// What a habit has to reach in a day to count as done, separate from how often the habit repeats
struct Goal: Codable, Equatable {
    var type: GoalType = .times
    /// Amount of `type` to reach, like 3 for 3 times a day
    var value: Int

    /// Lowest and highest value the add and edit habit forms accept
    static let valueRange: ClosedRange<Int> = 2...100
    /// Value a goal starts with when it's turned on
    static let defaultValue: Int = 3

    var isValid: Bool {
        Self.valueRange.contains(self.value)
    }
}

enum GoalType: String, Codable, CaseIterable {
    /// Done `value` times in a day
    case times
}
