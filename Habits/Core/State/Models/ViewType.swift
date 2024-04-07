//
//  ViewType.swift
//  Habits
//
//  Created by Tiago Fernandes on 07/04/2024.
//

import Foundation

enum ViewType: Int {
    case list = 0
    case calendar = 1
}

func getViewTypeSystemName(viewType: ViewType) -> String {
    return switch viewType {
        case .calendar: "list.bullet"
        default: "calendar"
    }
}
