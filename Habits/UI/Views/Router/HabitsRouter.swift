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
    internal private(set) var root: Root = Root(EmptyView())

    @Published
    private var navigationPaths: [Route] = []

    internal init() {
        replaceRoot(HabitsView())
    }

    internal func replaceRoot<V: View>(_ view: V) {
        self.root = Root(view)
    }

    internal func push<V: View>(_ view: V) {
        self.navigationPaths.append(Route(view))
    }

    internal func pop() {
        self.navigationPaths.removeLast()
    }

    internal func popTo(_ id: UUID) {
        guard let index: Int = navigationPaths.lastIndex(where: { (route: Route) in
                return route.id == id
            })
        else {
            return
        }

        self.navigationPaths.removeSubrange(index...navigationPaths.endIndex)
    }

    internal func popToRoot() {
        self.navigationPaths.removeAll()
    }
}
