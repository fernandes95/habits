//
//  AppConfig.swift
//  Habits
//
//  Created by Tiago Fernandes on 19/10/2026.
//

struct AppConfig: Codable {
    var startOfWeek: WeekDay

    internal func with(
        startOfWeek: WeekDay? = nil
    ) -> Self {
        return Self(
            startOfWeek: startOfWeek ?? self.startOfWeek
        )
    }

    static var empty: Self {
        return AppConfig(
            startOfWeek: WeekDay.sunday
        )
    }
}
