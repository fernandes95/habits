//
//  AppEnvironment.swift
//  Habits
//
//  Created by Tiago Fernandes on 07/09/2026.
//

import Foundation
import CoreLocation
import BackgroundTasks
import OSLog

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let habitsService: HabitsService
    let regionService: RegionServiceImpl
    let locationService: LocationService

    private init() {
        let habitsService = HabitsService()
        let regionService = RegionServiceImpl(habitsService: habitsService, regionRadius: .regionRadius)

        self.habitsService = habitsService
        self.regionService = regionService
        self.locationService = LocationService(
            habitsService: habitsService,
            regionService: regionService
        )
    }

    func regionMonitoring() {
        Task {
            try? await self.habitsService.load()
            try? await self.regionService.startMonitoringIfAuthorized()
            self.locationService.requestOneTimeLocation()
        }
    }

    /// Background refresh that keeps the reminders scheduled while the app isn't opened, also listed in Info.plist
    nonisolated static let reminderRefreshTaskId = "\(Bundle.main.bundleIdentifier!).reminders"

    /// Hours between background refreshes, iOS decides when it actually runs
    nonisolated static let reminderRefreshHours: Int = 12

    /// Asks iOS for the next background refresh, a new request replaces the pending one
    func scheduleReminderRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.reminderRefreshTaskId)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: Self.reminderRefreshHours, to: .now)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch let error {
            Logger.reminders.error("Background refresh wasn't scheduled: \(error.localizedDescription)")
        }
    }

    /// Schedules the reminders of the coming days again from the saved habits, and the next refresh
    func refreshReminders() async {
        Logger.reminders.debug("Background refresh started")
        self.scheduleReminderRefresh()
        do {
            // The app may have been launched only for this, the habits aren't loaded yet
            try await self.habitsService.load()
            try await self.habitsService.syncReminders()
        } catch let error {
            Logger.reminders.error("Background refresh failed: \(error.localizedDescription)")
        }
    }
}
