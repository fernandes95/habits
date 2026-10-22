//
//  AddToolbarButton.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

/// Adds the settings button to the navigation bar and pushes
/// `NewHabitView` onto the current tab's stack.
private struct AddToolbarButton<Sheet: View>: ViewModifier {
    @EnvironmentObject
    private var appRouter: AppRouter

    let sheet: () -> Sheet

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.appRouter.presentSheet(self.sheet())
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("habits_accessibility_new_habit")
            }
        }
    }
}

extension View {
    internal func addToolbarButton<Sheet: View>(
        @ViewBuilder sheet: @escaping () -> Sheet
    ) -> some View {
        self.modifier(AddToolbarButton(sheet: sheet))
    }
}
