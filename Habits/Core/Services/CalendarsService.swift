//
//  CalendarsService.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/06/2024.
//

import EventKit

class CalendarsService {
    private let storeService: DefaultStoreService = DefaultStoreService()
    private let eventStore: EKEventStore = EKEventStore()

    private var store: StoreEntity = StoreEntity(habits: [], habitsArchived: [])

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
        var calendar: EKCalendar? = if calendarType == .event {
            self.eventStore.defaultCalendarForNewEvents
        } else {
            self.eventStore.defaultCalendarForNewReminders()
        }

        do {
//            guard let calendarId: String = try await self.getCalendarId(calendarType: calendarType) else {
//                return try await createNewCalendar(calendarType: calendarType)
//            }
//               
//            guard let existingCalendar: EKCalendar = self.eventStore.calendar(withIdentifier: calendarId) else {
//                return try await createNewCalendar(calendarType: calendarType)
//            }
            guard let calendarId: String = try await self.getCalendarId(calendarType: calendarType),
                  let existingCalendar: EKCalendar = self.eventStore.calendar(withIdentifier: calendarId) else {
                return try await createNewCalendar(calendarType: calendarType)
            }

            calendar = existingCalendar
        } catch {}

        return calendar
    }

    private func getCalendarId(calendarType: EKEntityType) async throws -> String? {
        return switch calendarType {
            case .event:
                self.store.calendarEventId
            case .reminder:
                self.store.calendarReminderId
            @unknown default:
                nil
        }
    }

    private func createNewCalendar(calendarType: EKEntityType) async throws -> EKCalendar {
        let source: EKSource! = if calendarType == .event {
            eventStore.defaultCalendarForNewEvents?.source!
        } else {
            eventStore.defaultCalendarForNewReminders()?.source
        }

        let calendar: EKCalendar = EKCalendar(for: calendarType, eventStore: self.eventStore)
        calendar.title = "Habits"
        calendar.source = source

        try eventStore.saveCalendar(calendar, commit: true)
        try await saveCalendarId(calendarId: calendar.calendarIdentifier, calendarType: calendarType)

        return calendar
    }

    private func saveCalendarId(calendarId: String, calendarType: EKEntityType) async throws {
        switch calendarType {
            case .event:
                self.store.calendarEventId = calendarId
            case .reminder:
                self.store.calendarReminderId = calendarId
            @unknown default:
                return
        }

        try await storeService.save(self.store)
        try await self.load()
    }
}
