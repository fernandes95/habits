//
//  AddToolbarButton.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

/// Adds the settings button to the navigation bar and pushes
/// `NewHabitView` onto the current tab's stack.
private struct AddToolbarButton: ViewModifier {
    @EnvironmentObject
    private var router: HabitsRouter

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.router.push(NewHabitQuoteView())
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("habits_accessibility_new_habit")
            }
        }
    }
}

extension View {
    internal func addToolbarButton() -> some View {
        self.modifier(AddToolbarButton())
    }
}
