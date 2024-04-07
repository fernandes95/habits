//
//  CalendarView.swift
//  Habits
//
//  Created by Tiago Fernandes on 07/04/2024.
//

import Foundation
import SwiftUI

struct CalendarView: View {
    var body: some View {
        CalendarViewRepresentable()
    }
}

private struct CalendarViewRepresentable: UIViewRepresentable {
    @EnvironmentObject
    private var state: MainState

    func makeCoordinator() -> CalendarViewDelegate {
        CalendarViewDelegate()
    }

    class CalendarViewDelegate: NSObject, UICalendarViewDelegate {

        var calendarView: UICalendarView?
        var decorations: [Date?: UICalendarView.Decoration]

        override init() {

            // Create the date components for Valentine's day that
            // contain the calendar, year, month, and day.
            let valentinesDay = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                year: 2024,
                month: 2,
                day: 14
            )

            // Create a calendar decoration for Valentine's day.
            let heart = UICalendarView.Decoration.image(
                UIImage(systemName: "heart.fill"),
                color: UIColor.red,
                size: .large
            )

            decorations = [valentinesDay.date: heart]
        }

        // Return a decoration (if any) for the specified day.
        func calendarView(_ calendarView: UICalendarView,
                          decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            // Get a copy of the date components that only contain
            // the calendar, year, month, and day.
            let day = DateComponents(
                calendar: dateComponents.calendar,
                year: dateComponents.year,
                month: dateComponents.month,
                day: dateComponents.day
            )

            // Return any decoration saved for that date.
            return decorations[day.date]
        }
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        let gregorianCalendar = Calendar(identifier: .gregorian)

        calendarView.delegate = context.coordinator
        calendarView.calendar = gregorianCalendar
        calendarView.locale = Locale(identifier: Locale.current.language.languageCode?.identifier ?? "pt_PT")
        calendarView.fontDesign = .rounded

        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {

    }
}

#Preview {
    CalendarView()
        .environmentObject(MainState())
}
