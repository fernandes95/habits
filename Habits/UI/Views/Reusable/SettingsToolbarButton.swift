//
//  SettingsToolbarButton.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

/// Adds the settings button to the navigation bar and pushes
/// `SettingsView` onto the current tab's stack.
private struct SettingsToolbarButton: ViewModifier {
    @EnvironmentObject
    private var router: HabitsRouter

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    self.router.push(SettingsView())
                } label: {
                    Image(systemName: "gearshape.2.fill")
                }
                .accessibilityLabel("habits_accessibility_settings")
            }
        }
    }
}

extension View {
    internal func settingsToolbarButton() -> some View {
        self.modifier(SettingsToolbarButton())
    }
}
