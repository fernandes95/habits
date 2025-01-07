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

    private var randomQuote: LocalizedStringKey = ""

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

    internal init() {
        self.randomQuote = self.getRandomQuote()
    }

    private func getRandomQuote() -> LocalizedStringKey {
        let quotes: [LocalizedStringKey] =
        ["quote_one", "quote_two", "quote_three", "quote_four",
         "quote_five", "quote_six", "quote_seven", "quote_eight",
         "quote_nine", "quote_ten", "quote_eleven", "quote_twelve",
         "quote_thirteen", "quote_fourteen", "quote_fifteen", "quote_sixteen",
         "quote_seventeen", "quote_eighteen", "quote_nineteen", "quote_twenty",
         "quote_twenty_one", "quote_twenty_two", "quote_twenty_three",
         "quote_twenty_four", "quote_twenty_five", "quote_twenty_six",
         "quote_twenty_seven", "quote_twenty_eight", "quote_twenty_nine",
         "quote_thirty", "quote_thirty_one", "quote_thirty_two", "quote_thirty_three",
         "quote_thirty_four", "quote_thirty_five", "quote_thirty_six",
         "quote_thirty_seven", "quote_thirty_eight", "quote_thirty_nine",
         "quote_fourty", "quote_fourty_one"
        ]
        let randomIndex = Int.random(in: 0..<quotes.count)
        return quotes[randomIndex]
    }
}

#Preview {
    NewHabitQuoteView()
}
