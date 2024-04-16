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
    private let habitsService: HabitsService = HabitsService()
    private let locationService: LocationService = LocationService()
    private let notificationService: NotificationService = NotificationService()

    @Published
    var habits: [Habit] = []

    @Published
    var selectedDate: Date = Date.now

    func loadHabits(date: Date) async throws {
        self.habits = []
        self.selectedDate = date

        let uncheckedList: [Habit] = try await self.habitsService.loadUncheckedHabits(date: self.selectedDate)
        let checkedList: [Habit] = try await self.habitsService.loadCheckedHabits(date: self.selectedDate)

        self.habits = uncheckedList + checkedList
    }

    func getHabit(habit: Habit) async throws -> Habit {
        if let habitEntity: HabitEntity = try await self.habitsService.getHabit(id: habit.id) {
            return Habit(habitEntity: habitEntity, selectedDate: Date.now)
        } else {
            return habit
        }
    }

    func updateHabit(habit: Habit) async throws {
        do {
            try await self.habitsService.updateHabit(habit, selectedDate: self.selectedDate)

            if let location = habit.location {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    identifier: habit.id.uuidString
                )
            }
            try await loadHabits(date: self.selectedDate)
        } catch { }
    }

    func removeHabit(habitId: UUID) async throws {
        do {
            try await habitsService.removeHabit(habitId: habitId)
            self.locationService.stopMonitoringRegion(identifier: habitId.uuidString)
            try await loadHabits(date: self.selectedDate)
        } catch {}
    }

    func addHabit(_ habit: Habit) async throws {
        do {
            let newHabitId: UUID = try await habitsService.addHabit(habit)

            if let location = habit.location {
                self.locationService.startMonitoringRegion(
                    location: location.locationCoordinate,
                    identifier: newHabitId.uuidString
                )
            }
            try await loadHabits(date: self.selectedDate)
        } catch { }
    }

    func getLocationAuthorization() {
        self.locationService.locationAuthorization()
    }

    func getNotificationsAuthorization() async throws -> Bool {
        return try await self.notificationService.notificationAuthorization()
    }
}
