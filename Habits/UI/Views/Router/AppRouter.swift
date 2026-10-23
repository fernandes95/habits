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

    @Published
    internal var sheet: SheetRoute?

    internal let todo: HabitsRouter
    internal let habits: HabitsRouter
    internal let map: HabitsRouter

    internal init() {
        self.todo = HabitsRouter(
            root: TodoView()
                .settingsToolbarButton()
                .addToolbarButton { NewHabitContentView() }
        )
        self.habits = HabitsRouter(
            root: HabitsView()
                .settingsToolbarButton()
                .addToolbarButton { NewHabitContentView() }
        )
        self.map = HabitsRouter(root: HabitsMapView())
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

    internal func presentSheet<V: View>(
        _ view: V,
        detents: Set<PresentationDetent> = [.large]
    ) {
        self.sheet = SheetRoute(
            view
                .presentationDetents(detents)
                .presentationDragIndicator(.hidden)
        )
    }

    internal func dismissSheet() {
        self.sheet = nil
    }
}

internal struct SheetRoute: View, Identifiable {
    internal let id: UUID = UUID()
    private let view: AnyView

    internal init<V: View>(_ view: V) {
        self.view = AnyView(view)
    }

    internal var body: some View {
        self.view
    }
}
