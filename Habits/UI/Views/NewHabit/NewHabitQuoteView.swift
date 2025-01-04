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

    private var randomQuote: LocalizedStringKey {
        let quotes: [LocalizedStringKey] =
        ["quote_one", "quote_two", "quote_three", "quote_four",
         "quote_five", "quote_six", "quote_seven", "quote_eight",
         "quote_nine", "quote_ten", "quote_eleven", "quote_twelve",
         "quote_thirteen", "quote_fourteen", "quote_fivteen", "quote_sixteen",
         "quote_seventeen", "quote_eighteen", "quote_nineteen", "quote_twenty",
        ]
        let randomIndex = Int.random(in: 0..<quotes.count)
        return quotes[randomIndex]
    }

    var body: some View {
        VStack {
            Spacer()

            Text(self.randomQuote)

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
