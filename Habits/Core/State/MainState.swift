//
//  MainState.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation
import SwiftUI
import EventKit
import CoreLocation

@MainActor
class MainState: ObservableObject {
    private let habitsService: HabitsService
    private let locationService: LocationService
    private let notificationService: NotificationService = NotificationService()

    @Published
    var habits: [Habit] = []

    /// Every saved habit regardless of the selected date, newest first
    @Published
    var allHabits: [Habit] = []

    @Published
    var configs: AppConfig = AppConfig.empty

    @Published
    var notificationStatus: UNAuthorizationStatus = .notDetermined

    @Published
    var selectedDate: Date = .now

    /// Last known user location, nil while unknown or without location permission
    @Published
    var currentLocation: CLLocation?

    /// Location permission, nil until it's known. Updated when the user changes it in Settings
    @Published
    var locationStatus: CLAuthorizationStatus?

    /// Habits of each loaded day, keyed by start of day
    private var habitsByDay: [Date: [Habit]] = [:]

    /// Progress of each day (0...1) keyed by the start of the day.
    /// Days without habits have no entry.
    @Published
    var dayProgress: [Date: Double] = [:]

    var duplicatedHabits: [HabitEntity]?

    /// Calendar used for every week related calculation, follows the start of the week setting
    var calendar: Calendar {
        return self.configs.calendar
    }

    init(environment: AppEnvironment) {
        self.habitsService = environment.habitsService
        self.locationService = environment.locationService

        self.locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$currentLocation)

        self.locationService.$status
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$locationStatus)
    }

    func initHabits() async {
        do {
            try await self.habitsService.load()
            try await self.habitsService.updateInstallDate()
            self.getConfigs()
            try await self.loadHabits(date: selectedDate)
            self.requestLocationAuthorizationIfNeeded()
        } catch {
            print(error.localizedDescription)
        }
    }

    func requestLocationAuthorizationIfNeeded() {
        self.locationService.requestOneTimeLocation()
    }

    /// Asks for a fresh user location, only when location was already authorized
    func refreshCurrentLocation() {
        self.locationService.requestOneTimeLocation()
    }

    /// Distance in meters from the user to `location`, nil while the user location is unknown
    func distance(to location: Habit.Location) -> CLLocationDistance? {
        guard let currentLocation else { return nil }
        return currentLocation.distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
    }

    /// True when `habit` has its location reminder on but it can't remind,
    /// `Always` location isn't allowed (turned off in Settings for example).
    /// The reminder is kept and starts again once `Always` is allowed.
    func isLocationReminderPaused(_ habit: Habit) -> Bool {
        guard let locationStatus, locationStatus != .authorizedAlways else { return false }
        return habit.location != nil && habit.hasLocationReminder && habit.endDate.endOfDay >= .now
    }

    /// Habits with a paused location reminder, see `isLocationReminderPaused`
    var pausedLocationReminders: [Habit] {
        return self.allHabits.filter { self.isLocationReminderPaused($0) }
    }

    /// Get exportable document
    func getDataDocument() async throws -> ExportableDocument {
        return await self.habitsService.exportDataDocument()
    }

    /// Get all habits from `Imported Data`
    ///
    /// - Parameter data: Imported data
    func importHabits(url: URL) async throws -> Bool? {
        self.duplicatedHabits = try await self.habitsService.importHabits(from: url)
        try await self.updateInstallDate()

        guard let habits: [HabitEntity] = self.duplicatedHabits else { return nil }

        if habits.isEmpty {
            try await self.loadHabits(date: self.selectedDate)
            return false
        } else {
            return true
        }
    }

    /// Manage duplicated habits
    ///
    /// - Parameter resolution: Conflict Resolution type
    func manageDuplicatedHabits(_ resolution: ConflictResolution) async throws {
        switch resolution {
        case .delete: self.duplicatedHabits = []
        default: try await self.habitsService.manageDuplicates(
            habits: self.duplicatedHabits ?? [],
            resolution: resolution
        )
        try await self.updateInstallDate()
        try await self.loadHabits(date: self.selectedDate)
        }
    }

    /// Moves the install date back when an imported habit is older, the week view can go back to it
    private func updateInstallDate() async throws {
        try await self.habitsService.updateInstallDate()
        self.getConfigs()
    }

    /// Reloads the whole block around `date`.
    /// Use it after any change to the habits, since a change can affect other days too.
    func loadHabits(date: Date, animated: Bool = true) async throws {
        self.selectedDate = date

        let block = try await self.habitsService.loadHabits(days: self.blockDays(around: date))

        self.habitsByDay = block
        self.updateProgress()
        self.allHabits = self.habitsService.habits
            .map { Habit(habitEntity: $0) }
            .sorted { $0.createdDate > $1.createdDate }
        // The user may have moved to another day while loading, show whatever is selected now
        self.showHabits(of: self.selectedDate, animated: animated)
    }

    /// Selects a day using the loaded block, and loads the missing days around it if needed.
    func selectDate(_ date: Date, animated: Bool = true) async throws {
        self.selectedDate = date

        let wasLoaded = self.habitsByDay[date.startOfDay] != nil
        if wasLoaded {
            self.showHabits(of: date, animated: animated)
        }

        let missingDays = self.blockDays(around: date).filter { self.habitsByDay[$0] == nil }
        guard !missingDays.isEmpty else { return }

        let loaded = try await self.habitsService.loadHabits(days: missingDays)
        self.habitsByDay.merge(loaded) { _, new in new }
        self.updateProgress()

        if !wasLoaded && self.selectedDate.startOfDay == date.startOfDay {
            self.showHabits(of: date, animated: animated)
        }
    }

    /// Week of `date` plus the previous and next weeks
    private func blockDays(around date: Date) -> [Date] {
        let calendar = self.calendar
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return [date.startOfDay]
        }
        return (-7..<14).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)?.startOfDay
        }
    }

    private func showHabits(of date: Date, animated: Bool) {
        let list: [Habit] = self.habitsByDay[date.startOfDay] ?? []
        guard list != self.habits else { return }

        if animated {
            withAnimation(.snappy) { self.habits = list }
        } else {
            self.habits = list
        }
    }

    private func updateProgress() {
        self.dayProgress = self.habitsByDay.compactMapValues { list in
            guard !list.isEmpty else { return nil }
            return list.reduce(0) { $0 + $1.dayProgress } / Double(list.count)
        }
    }

    /// Get original habit if it doesn't exists returns itself
    ///
    /// - Parameter habit: Habit to get id
    /// - Returns: Habit
    func getHabit(habit: Habit) async throws -> Habit {
        if let habitEntity: HabitEntity = try await self.habitsService.getHabit(id: habit.id) {
            return Habit(habitEntity: habitEntity, selectedDate: .now)
        } else {
            return habit
        }
    }

    /// Updates Habit and loads all habits from selected date
    ///
    /// - Parameter habit: Habit to update
    func updateHabit(habit: Habit) async throws {
        do {
            try await self.habitsService.updateHabit(habit, selectedDate: self.selectedDate)

            // Only habits with the location reminder on are monitored, the location alone isn't enough
            if let location = habit.location, habit.hasLocationReminder {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    habitIdentifier: habit.id.uuidString,
                    habitName: habit.name
                )
            }
            try await loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Removes the last step of `habit` on the selected date and loads all habits from selected date
    ///
    /// - Parameter habit: Habit with a goal to update
    func undoLastStep(habit: Habit) async throws {
        do {
            try await self.habitsService.undoLastStep(habit, selectedDate: self.selectedDate)
            try await loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Clears the progress of `habit` on the selected date and loads all habits from selected date
    ///
    /// - Parameter habit: Habit with a goal to update
    func resetProgress(habit: Habit) async throws {
        do {
            try await self.habitsService.resetProgress(habit, selectedDate: self.selectedDate)
            try await loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Saves edited Habit settings without changing the status of any day,
    /// and loads all habits from selected date
    ///
    /// - Parameter habit: Habit with the edited settings
    func editHabit(habit: Habit) async throws {
        do {
            try await self.habitsService.editHabit(habit)

            if let location = habit.location, habit.hasLocationReminder {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    habitIdentifier: habit.id.uuidString,
                    habitName: habit.name
                )
            } else {
                self.locationService.stopMonitoringRegion(
                    habitIdentifier: habit.id.uuidString,
                    habitName: habit.name
                )
            }
            try await loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Removes Habit, stops monitoring if needed and loads all habits from selected date
    ///
    /// - Parameter habit: Habit UUID to remove
    func removeHabit(habitId: UUID) async throws {
        do {
            try await habitsService.removeHabit(habitId: habitId)
            self.locationService.stopMonitoringRegion(
                habitIdentifier: habitId.uuidString,
                habitName: ""
            )
            try await loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Adds new Habit and loads all habits from selected date
    ///
    /// - Parameter habit: Habit UUID to remove
    func addHabit(_ habit: Habit) async throws {
        do {
            let newHabitId: UUID = try await self.habitsService.addHabit(habit)

            if let location = habit.location, habit.hasLocationReminder {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    habitIdentifier: newHabitId.uuidString,
                    habitName: habit.name
                )
            }
            try await self.loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Gets saved configurations
    ///
    func getConfigs() {
        self.configs = self.habitsService.appConfigs
    }

    /// Saves new configurations
    ///
    /// - Parameter configs: Configurations to change.
    func saveConfigs(_ configs: AppConfig) async {
        do {
            try await self.habitsService.updateAppConfigs(configs)
            self.configs = configs
            // The loaded block depends on where the week starts, reload it with the new weeks
            try await self.loadHabits(date: self.selectedDate, animated: false)
        } catch let error { print(error.localizedDescription) }
    }

    /// Get Location Authorization Status
    func getLocationAuthorizationStatus() -> Bool {
        let status = self.locationService.getAuthorizationStatus()
        return status == .authorizedAlways
    }

    /// Every saved habit with a location, regardless of the selected date
    func getLocationHabits() -> [Habit] {
        return self.habitsService.habits
            .filter { $0.location != nil }
            .map { Habit(habitEntity: $0) }
    }

    /// Location reminders are only delivered with the `Always` location permission
    ///
    /// - Parameter habit: Habit about to be saved
    /// - Returns: `true` when `habit` has a location reminder that can't be delivered yet
    func needsLocationAlwaysAuthorization(for habit: Habit) -> Bool {
        return habit.location != nil && habit.hasLocationReminder && !self.getLocationAuthorizationStatus()
    }

    /// Get Notification Authorization Status
    func getNotificationsAuthorizationStatus() async throws -> Bool {
        let status = await self.notificationService.getNotificationStatus()
        self.notificationStatus = status
        return status == .authorized
    }

    /// Get Notifications Authorization
    func getNotificationsAuthorization() async throws {
        if self.notificationStatus == .notDetermined {
            _ = try await self.notificationService.notificationAuthorization()
        }
    }

    func requestLocation() {
        self.locationService.requestLocationAuthorization()
    }

    func requestAlwaysLocation() {
        self.locationService.requestAlwaysLocationAuthorization()
    }
}
