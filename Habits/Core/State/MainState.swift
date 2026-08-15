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

    var duplicatedHabits: [HabitEntity]?

    init(habitsService: HabitsService) {
        self.habitsService = habitsService
        self.locationService = LocationService(habitsService: habitsService)
    }

    func initHabits() async {
        do {
            try await self.habitsService.load()
            try await self.loadHabits(date: selectedDate)
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

    /// Get all habits from `Selected Date`
    ///
    /// - Parameter date: Selected date
    func loadHabits(date: Date) async throws {
        self.habits = []
        self.selectedDate = date

        let uncheckedList: [Habit] = try await self.habitsService.loadUncheckedHabits(date: self.selectedDate)
        let checkedList: [Habit] = try await self.habitsService.loadCheckedHabits(date: self.selectedDate)

        self.habits = uncheckedList + checkedList
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
            let newHabitId: UUID = try await habitsService.addHabit(habit)

            if let location = habit.location {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    habitIdentifier: newHabitId.uuidString,
                    habitName: habit.name
                )
            }
            try await loadHabits(date: self.selectedDate)
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

    func forceStartUpdatingLocation() {
        self.locationService.startTrackingWithBackgroundSupport()
    }

    func forceStopUpdatingLocation() {
        self.locationService.stopUpdatingLocation()
    }
}
