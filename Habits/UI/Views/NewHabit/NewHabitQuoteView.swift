//
//  NewHabitQuoteView.swift
//  Habits
//
//  Created by Tiago Fernandes on 12/09/2024.
//

import SwiftUI

struct NewHabitQuoteView: View {
    var body: some View {
        VStack {
            Spacer()

            Text("Random quote here")

            Spacer()

            Button("Continue") {

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
