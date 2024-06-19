//
//  CalendarsService.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/06/2024.
//

import EventKit
import UIKit

class CalendarsService {
    private let storeService: DefaultStoreService = DefaultStoreService()
    private let eventStore: EKEventStore = EKEventStore()
    private let calendarProperties: (name: String, color: UIColor) =
    ("Habits", UIColor(cgColor: CGColor(red: 0.188, green: 0.178, blue: 0.183, alpha: 1)))

    private var store: StoreEntity = StoreEntity(habits: [], habitsArchived: [], calendarEventId: nil, calendarReminderId: nil)

    init() {
        Task {
            try await load()
        }
    }

    /// Gets store from local file
    private func load() async throws {
        self.store = try await storeService.load()
    }

    internal func getCalendar(calendarType: EKEntityType) async throws -> EKCalendar? {
        guard let existingCalendar: EKCalendar = try await self.getExistingCalendar() else {
            return try await createNewCalendar(calendarType: calendarType)
        }

        return existingCalendar
    }

    private func getExistingCalendar() async throws -> EKCalendar? {
        var returnableCalendar: EKCalendar?

        try await self.load()

        guard self.store.calendarEventId != nil else {
            return nil
        }

        let calendars = self.eventStore.calendars(for: .event)
        for calendar in calendars {
            if calendar.calendarIdentifier == self.store.calendarEventId {
                returnableCalendar = calendar
                break
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

        var newCalendar: EKCalendar = EKCalendar(for: calendarType, eventStore: self.eventStore)
        newCalendar.title = self.calendarProperties.name
        newCalendar.cgColor = self.calendarProperties.color.cgColor
        newCalendar.source = source

        try self.eventStore.saveCalendar(newCalendar, commit: true)
        self.store.calendarEventId = newCalendar.calendarIdentifier
        try await storeService.save(self.store)
        try await self.load()

//        let calendars = self.eventStore.calendars(for: calendarType)
//        for calendar in calendars {
//            if calendar.title == self.calendarProperties.name {
//                self.store.calendarEventId = calendar.calendarIdentifier
//                try await storeService.save(self.store)
//                try await self.load()
//                newCalendar = calendar
//                break
//            }
//        }

        return newCalendar
    }
}
