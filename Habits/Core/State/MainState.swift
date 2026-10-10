//
//  MainState.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation
import SwiftUI
import EventKit

@MainActor
class MainState: ObservableObject {
    private let habitsService: HabitsService
    private let locationService: LocationService
    private let notificationService: NotificationService = NotificationService()

    @Published
    var habits: [Habit] = []

    @Published
    var locationStatus: CLAuthorizationStatus = .notDetermined

    @Published
    var notificationStatus: UNAuthorizationStatus = .notDetermined

    @Published
    var selectedDate: Date = .now

    /// Habits of each loaded day, keyed by start of day
    private var habitsByDay: [Date: [Habit]] = [:]

    /// Progress of each day (0...1) keyed by the start of the day.
    /// Days without habits have no entry.
    @Published
    var dayProgress: [Date: Double] = [:]

    var duplicatedHabits: [HabitEntity]?

    init(environment: AppEnvironment) {
        self.habitsService = environment.habitsService
        self.locationService = environment.locationService
    }

    func initHabits() async {
        do {
            try await self.habitsService.load()
            try await self.loadHabits(date: selectedDate)
            self.requestLocationAuthorizationIfNeeded()
        } catch {
            print(error.localizedDescription)
        }
    }

    func requestLocationAuthorizationIfNeeded() {
        self.locationService.requestOneTimeLocation()
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
        try await self.loadHabits(date: self.selectedDate)
        }
    }

    /// Reloads the whole block around `date`.
    /// Use it after any change to the habits, since a change can affect other days too.
    func loadHabits(date: Date, animated: Bool = true) async throws {
        self.selectedDate = date

        let block = try await self.habitsService.loadHabits(days: Self.blockDays(around: date))

        self.habitsByDay = block
        self.updateProgress()
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

        let missingDays = Self.blockDays(around: date).filter { self.habitsByDay[$0] == nil }
        guard !missingDays.isEmpty else { return }

        let loaded = try await self.habitsService.loadHabits(days: missingDays)
        self.habitsByDay.merge(loaded) { _, new in new }
        self.updateProgress()

        if !wasLoaded && self.selectedDate.startOfDay == date.startOfDay {
            self.showHabits(of: date, animated: animated)
        }
    }

    /// Week of `date` plus the previous and next weeks
    private static func blockDays(around date: Date) -> [Date] {
        let calendar = Calendar.current
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

            if let location = habit.location {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    habitIdentifier: habit.id.uuidString,
                    habitName: habit.name
                )
            }
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

            if let location = habit.location {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
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

            if let location = habit.location {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    habitIdentifier: newHabitId.uuidString,
                    habitName: habit.name
                )
            }
            try await self.loadHabits(date: self.selectedDate)
        } catch let error { print(error.localizedDescription) }
    }

    /// Get Location Authorization Status
    func getLocationAuthorizationStatus() -> Bool {
        let status = self.locationService.getAuthorizationStatus()
        self.locationStatus = status
        return status == .authorizedAlways
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
