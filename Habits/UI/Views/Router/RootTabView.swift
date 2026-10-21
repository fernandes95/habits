//
//  RootTabView.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

internal struct RootTabView: View {
    @StateObject
    private var appRouter: AppRouter = AppRouter()

    internal var body: some View {
        TabView(selection: self.tabSelection) {
            Tab("", systemImage: "checklist", value: AppTab.todo) {
                TabRoot(router: self.appRouter.todo)
            }
            Tab("", systemImage: "repeat", value: AppTab.habits) {
                TabRoot(router: self.appRouter.habits)
            }
            Tab("", systemImage: "map", value: AppTab.map) {
                TabRoot(router: self.appRouter.map)
            }
        }
        .environmentObject(self.appRouter)
    }

    /// Routes every tap through `select` so re-tapping a tab pops it to root
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { self.appRouter.selectedTab },
            set: { self.appRouter.select($0) }
        )
    }
}

/// Injects the tab's own router, so existing views keep using
/// `@EnvironmentObject var router: HabitsRouter` unchanged.
private struct TabRoot: View {
    @ObservedObject
    var router: HabitsRouter

    var body: some View {
        self.router.root
            .environmentObject(self.router)
    }
}
