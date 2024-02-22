//
//  HabitRouteIdEnvironmentKey.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/02/2024.
//

import SwiftUI

private struct HabitRouteIdEnvironmentKey: EnvironmentKey {
    static let defaultValue: UUID = UUID()
}

extension EnvironmentValues {
    internal var habitRouteId: UUID {
        get { self[HabitRouteIdEnvironmentKey.self] }
        set { self[HabitRouteIdEnvironmentKey.self] = newValue }
    }
}

extension View {
    internal func habitRouteId(_ id: UUID) -> some View {
        return self.environment(\.habitRouteId, id)
    }
}
