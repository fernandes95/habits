//
//  RegionServiceImpl.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/04/2024.
//

import Foundation
import CoreLocation
import OSLog

@MainActor
final class RegionServiceImpl: RegionService {
    private let habitsService: HabitsService
    private let notificationService: NotificationService = NotificationService()
    private static let monitorName = "MonitorID"
    private var monitorTask: Task<CLMonitor, Never>?
    private var eventTask: Task<Void, Never>?
    private var serviceSession: CLServiceSession?
    private let regionRadius: CLLocationDistance

    init(habitsService: HabitsService, regionRadius: CLLocationDistance) {
        self.habitsService = habitsService
        self.regionRadius = regionRadius
    }

    private func currentMonitor() async -> CLMonitor {
        if let monitorTask { return await monitorTask.value }
            let task = Task { await CLMonitor(Self.monitorName) }
            self.monitorTask = task
            return await task.value
    }

    private func consumeEvents(_ monitor: CLMonitor) async {
        do {
            for try await event in await monitor.events {
                switch event.state {
                case .satisfied:
                    Logger.location.debug("⬆️ CL MONITOR ENTERED REGION (Time: \(Date.now))")
                    try? await remindUser(id: event.identifier)
                case .unsatisfied:
                    Logger.location.debug("⬇️ CL MONITOR EXITED REGION")
                    if (try? await validateRegion(identifier: event.identifier)) == true {
                        try? await stopMonitoringRegion(habitIdentifier: event.identifier)
                    }
                default:
                    Logger.location.debug("CL MONITOR unknown state: \(String(describing: event))")
                }
            }
                Logger.location.error("CL MONITOR stream ended — monitoring is dead until relaunch")
            } catch {
                Logger.location.error("CL MONITOR stream failed: \(error.localizedDescription)")
            }

    }

    private func remindUser(id: String) async throws {
        guard let habitEntity: HabitEntity = try await self.habitsService.getHabitEntity(id: id) else {
            try await stopMonitoringRegion(habitIdentifier: id)
            return
        }

        // stop monitoring habit that already finished
        if habitEntity.endDate.startOfDay < .now.startOfDay {
            try await self.stopMonitoringRegion(habitIdentifier: id)
            return
        }

        // Check if the habit is already completed today
        let isChecked = habitEntity.statusList.first(where: { $0.date.startOfDay == .now.startOfDay })?.isChecked
        guard isChecked != true else {
            // Already completed today, no notification needed
            return
        }
        guard !(try await self.habitsService.verifyHabitWasNotified(habitId: habitEntity.id)) else {
            return
        }

        try await self.notificationService.requestInstantNotification(subTitle: "Don't forget to: \(habitEntity.name)")
        try await self.habitsService.notifiedHabit(habitId: habitEntity.id)
    }

    func monitorRegion(center: CLLocationCoordinate2D, habitIdentifier: String, habitName: String) async throws {
        // making sure to remove if habit is being updated
        // CLMonitor.add doesn't update if it exists
        try await stopMonitoringRegion(habitIdentifier: habitIdentifier, habitName: habitName)
        await self.currentMonitor().add(
            CLMonitor.CircularGeographicCondition(center: center, radius: self.regionRadius),
            identifier: habitIdentifier,
            assuming: .unsatisfied
        )
        Logger.location.debug("🔎✅ CL MONITOR Started monitoring region for HABIT: \(habitName)")
    }

    func stopMonitoringRegion(habitIdentifier: String, habitName: String? = nil) async throws {
        await self.currentMonitor().remove(habitIdentifier)
        Logger.location.debug("🔎🛑 CL MONITOR Stoped monitoring region for HABIT: \(habitName ?? habitIdentifier)")
    }

    func validateRegion(identifier: String) async throws -> Bool {
        guard let habits: [Habit] = try? await self.habitsService.loadCheckedHabits(date: .now) else { return false }

        let habitIsChecked = habits.first(where: { $0.id.uuidString == identifier })?.isChecked

        return habitIsChecked ?? false
    }

    func manageRegions() async throws {
        var habitsMonitored: [String] = []
        try await self.habitsService.loadIfNeeded()
        let habits = try await self.habitsService.getHabits(date: .now, hasFilterLocation: true)
        let allHabits = try await self.habitsService.getHabits(date: .now)

        let monitor = await currentMonitor()
        for identifier in await monitor.identifiers {
            guard let habitEntity = try await self.habitsService.getHabit(id: identifier) else {
                try await stopMonitoringRegion(habitIdentifier: identifier)
                continue
            }

            if habits.contains(where: { $0.id.uuidString == identifier }) {
                habitsMonitored.append(habitEntity.id.uuidString)
            } else {
                try await stopMonitoringRegion(habitIdentifier: identifier, habitName: habitEntity.name)
            }
        }

        for habit in habits where !habitsMonitored.contains(where: { $0 == habit.id.uuidString }) {
            try await monitorRegion(
                center: habit.location!.locationCoordinate,
                habitIdentifier: habit.id.uuidString,
                habitName: habit.name,
            )
        }

        // DEBUG LOGS
        Logger.location.debug("\n **** Regions being monitored ****")
        for identifier in await monitor.identifiers {
            if let habit = try await self.habitsService.getHabit(id: identifier) {
                Logger.location.debug("► Name: \(habit.name)")
            } else {
                Logger.location.debug("► Identifier: \(identifier)")
            }
        }
        Logger.location.debug("\n **** End of Regions being monitored ****")
        // END OF DEBUG LOGS
    }

    func checkAlreadyInsideRegion(currentLocation: CLLocation) async throws {
        let habits = try await habitsService.getHabits(date: .now)

        for habit in habits {
            guard let coord = habit.location?.locationCoordinate else { continue }
            let habitLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = currentLocation.distance(from: habitLocation)

            if distance <= self.regionRadius {
                Logger.location.debug("📍 Already inside region at launch for: \(habit.name)")
                try await remindUser(id: habit.id.uuidString)
            }
        }
    }

    func startMonitoringIfAuthorized() async throws {
        if self.serviceSession == nil {
           self.serviceSession = CLServiceSession(authorization: .always)
       }

        if self.eventTask == nil {
            self.eventTask = Task { [weak self] in
                guard let self else { return }
                let monitor = await self.currentMonitor()
                await self.consumeEvents(monitor)
            }
        }
        try await self.manageRegions()
    }
}
