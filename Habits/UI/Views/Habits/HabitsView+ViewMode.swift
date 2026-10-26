//
//  HabitsView+ViewMode.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/10/2026.
//

import SwiftUI

extension HabitsView {
    /// What the habits tab lists, picked from the toolbar menu
    enum ViewMode: String, CaseIterable, Identifiable {
        case today
        case week
        case all

        var id: String { self.rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .today: "habits_mode_today"
            case .week: "habits_mode_week"
            case .all: "habits_mode_all"
            }
        }

        var systemImage: String {
            switch self {
            case .today: "sun.max"
            case .week: "calendar"
            case .all: "list.bullet"
            }
        }
    }
}
