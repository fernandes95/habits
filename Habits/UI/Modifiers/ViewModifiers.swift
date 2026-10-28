//
//  ViewModifiers.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/05/2024.
//

import Foundation
import SwiftUI

extension View {

    /// Hide or show the view based on a boolean value.
    ///
    /// Example for visibility:
    ///
    ///     Text("Label")
    ///         .isHidden(true)
    ///
    /// - Parameters:
    ///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
    ///
    @ViewBuilder func isHidden(_ hidden: Bool) -> some View {
        if !hidden {
            self
        }
    }

    /// Lets the user close the keyboard of a form by dragging the form down,
    /// needed by the number pads that have no return key.
    func keyboardDismissable() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}
