//
//  HabitsRouter.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/02/2024.
//

import SwiftUI

internal class HabitsRouter: ObservableObject {

    internal struct Root: View {
        private let view: AnyView

        @EnvironmentObject
        private var router: HabitsRouter

        internal var body: some View {
            NavigationStack(path: self.$router.navigationPaths) {
                self.view.navigationDestination(
                    for: HabitsRouter.Route.self
                ) { (route: HabitsRouter.Route) in
                    route
                        // Pushed screens are full screen, the tab bar only shows on tab roots
                        .toolbar(.hidden, for: .tabBar)
                }
                .sheet(item: self.$router.sheet) { (route: HabitsRouter.Route) in
                    route
                }
            }
        }

        internal init<V: View>(_ view: V) {
            self.view = AnyView(view)
        }
    }

    internal struct Route: View, Identifiable, Hashable {
        internal let id: UUID = UUID()
        private let view: AnyView

        internal var body: some View {
            self.view
        }

        internal init<V: View>(_ view: V) {
            self.view = AnyView(view.environment(\.habitRouteId, self.id))
        }

        internal func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }

        internal static func == (
            lhs: HabitsRouter.Route,
            rhs: HabitsRouter.Route
        ) -> Bool {
            return lhs.id == rhs.id
        }
    }

    @Published
    internal private(set) var root: Root

    @Published
    private var navigationPaths: [Route] = []

    @Published
    private var sheet: Route?

    /// Shows `view` as a bottom sheet over the current tab
    internal func present<V: View>(
        _ view: V,
        detents: Set<PresentationDetent> = [.medium, .large]
    ) {
        self.sheet = Route(
            view
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
        )
    }

    internal func dismissSheet() {
        self.sheet = nil
    }

    internal var isAtRoot: Bool {
       self.navigationPaths.isEmpty
    }

    internal init<V: View>(root: V) {
        self.root = Root(root)
    }

    internal func replaceRoot<V: View>(_ view: V) {
        self.root = Root(view)
        self.navigationPaths.removeAll()
    }

    internal func push<V: View>(_ view: V) {
        self.navigationPaths.append(Route(view))
    }

    internal func pop() {
        guard !self.navigationPaths.isEmpty else { return }
        self.navigationPaths.removeLast()
    }

    /// Removes the route with `id` and everything pushed after it
    internal func popTo(_ id: UUID) {
        guard let index: Int = self.navigationPaths.lastIndex(where: { (route: Route) in
                return route.id == id
            })
        else {
            return
        }

        self.navigationPaths.removeSubrange(index...)
    }

    internal func popToRoot() {
        self.navigationPaths.removeAll()
    }
}
