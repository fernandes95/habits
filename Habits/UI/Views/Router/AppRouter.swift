//
//  AppRouter.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

internal enum AppTab: Hashable {
    case todo
    case habits
    case map
}

/// Owns the selected tab and one `HabitsRouter` per tab.
@MainActor
internal final class AppRouter: ObservableObject {
    @Published
    internal var selectedTab: AppTab = .habits

    internal let todo: HabitsRouter
    internal let habits: HabitsRouter
    internal let map: HabitsRouter

    internal init() {
        self.todo = HabitsRouter(root: TodoView().settingsToolbarButton().addToolbarButton())
        self.habits = HabitsRouter(root: HabitsView().settingsToolbarButton().addToolbarButton())
        self.map = HabitsRouter(root: HabitsMapView().settingsToolbarButton().addToolbarButton())
    }

    internal func router(for tab: AppTab) -> HabitsRouter {
        switch tab {
        case .todo: return self.todo
        case .habits: return self.habits
        case .map: return self.map
        }
    }

    /// Tapping the tab that is already selected goes back to its root, like the system apps
    internal func select(_ tab: AppTab) {
        if tab == self.selectedTab {
            self.router(for: tab).popToRoot()
        } else {
            self.selectedTab = tab
        }
    }
}
