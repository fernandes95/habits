//
//  NewHabitQuoteView.swift
//  Habits
//
//  Created by Tiago Fernandes on 12/09/2024.
//

import SwiftUI

struct NewHabitQuoteView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    var body: some View {
        VStack {
            Spacer()

            Text("Random quote here")

            Spacer()
        }
        .padding(16)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("general_next") {
                    self.router.push(NewHabitNameView())
                }
            }
        }
    }
}

#Preview {
    NewHabitQuoteView()
}
