//
//  CalendarsService.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/06/2024.
//

import EventKit

class CalendarsService {
    private let eventStore: EKEventStore = EKEventStore()
    private let calendarProperties: (name: String, color: CGColor) =
        ("Habits", CGColor(red: 188, green: 178, blue: 183, alpha: 0.52))
    private var store: StoreEntity = StoreEntity(habits: [], habitsArchived: [])

    internal func getCalendar(calendarType: EKEntityType) async throws -> EKCalendar? {
        guard let existingCalendar: EKCalendar = self.getExistingCalendar() else {
            return try await createNewCalendar(calendarType: calendarType)
        }

        return existingCalendar
    }

    private func getExistingCalendar() -> EKCalendar? {
        var returnableCalendar: EKCalendar?

        let calendars = self.eventStore.calendars(for: .event)
        for calendar in calendars {
            print(calendar.title)
            if calendar.title == self.calendarProperties.name &&
                calendar.cgColor == self.calendarProperties.color {
                returnableCalendar = calendar
            }
        }

        return returnableCalendar
    }

    private func createNewCalendar(calendarType: EKEntityType) async throws -> EKCalendar {
        let source: EKSource! = if calendarType == .event {
            self.eventStore.defaultCalendarForNewEvents?.source!
        } else {
            self.eventStore.defaultCalendarForNewReminders()?.source
        }

        let calendar: EKCalendar = EKCalendar(for: calendarType, eventStore: self.eventStore)
        calendar.title = self.calendarProperties.name
        calendar.cgColor = self.calendarProperties.color
        calendar.source = source

        try self.eventStore.saveCalendar(calendar, commit: true)

        return calendar
    }
}
