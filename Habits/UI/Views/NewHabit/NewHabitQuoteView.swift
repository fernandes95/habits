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

            Button("general_continue") {
                self.router.push(NewHabitNameView())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(15)
        }
        .padding(16)
    }
}

#Preview {
    NewHabitQuoteView()
}
