//
//  RegionService.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/04/2024.
//

import Foundation
import CoreLocation

@available(iOS 17.0, *)
class RegionServiceNew: RegionService {
    private let habitsService: HabitsService = HabitsService()
    private let notificationService: NotificationService = NotificationService()
    private var monitor: CLMonitor?

    init() {
        Task {
            try await startMonitorRegions()
        }
    }

    private func startMonitorRegions() async throws {
        if self.monitor == nil {
            self.monitor = await CLMonitor("MonitorID")
        }

        guard let monitor else { return }
        for try await event in await monitor.events {
                switch event.state {
                case .satisfied: // callback when user ENTERS any of the registered regions.
                    print("⬆️ CL MONITOR ENTERED REGION (Time: \(Date.now)")
                    try await remindUser(id: event.identifier)
                case .unknown, .unsatisfied: // callback when user EXITS any of the registered regions.
                    print("⬇️ CL MONITOR EXITED REGION")
                    if try await validateRegion(identifier: event.identifier) {
                        try await stopMonitoringRegion(habitIdentifier: event.identifier)
                    }
                default:
                    print("CL MONITOR No Location Registered")
                }
        }
    }

    private func remindUser(id: String) async throws {
        guard let habitEntity: HabitEntity = try await self.habitsService.getHabitEntity(id: id) else {
            try await stopMonitoringRegion(habitIdentifier: id)
            return
        }

        // stop monitoring habit that already finished
        if habitEntity.endDate.startOfDay < .now.startOfDay {
            try await stopMonitoringRegion(habitIdentifier: id)
            return
        }

        // Check if the habit is already completed today
        let isChecked = habitEntity.statusList.first(where: { $0.date.startOfDay == .now.startOfDay })?.isChecked
        guard isChecked != true else {
            // Already completed today, no notification needed
            return
        }

        try await notificationService.requestInstantNotification(subTitle: "Don't forget to: \(habitEntity.name)")
    }

    func monitorRegion(center: CLLocationCoordinate2D, habitIdentifier: String, habitName: String) async throws {
        // making sure to remove if habit is being updated
        // CLMonitor.add doesn't update if it exists
        try await stopMonitoringRegion(habitIdentifier: habitIdentifier, habitName: habitName)
        await monitor?.add(
            CLMonitor.CircularGeographicCondition(center: center, radius: 5),
            identifier: habitIdentifier,
            assuming: .unsatisfied
        )
        print("🔎✅ CL MONITOR Started monitoring region for HABIT: \(habitName)")
    }

    func stopMonitoringRegion(habitIdentifier: String, habitName: String? = nil) async throws {
        await monitor?.remove(habitIdentifier)
        print("🔎🛑 CL MONITOR Stoped monitoring region for HABIT: \(habitName ?? habitIdentifier)")
    }

    func validateRegion(identifier: String) async throws -> Bool {
        guard let habits: [Habit] = try? await habitsService.loadCheckedHabits(date: .now) else { return false }

        let habitIsChecked = habits.first(where: { $0.id.uuidString == identifier })?.isChecked

        return habitIsChecked ?? false
    }

    private func removeAllEvents() async throws {
        if let monitor {
            for identifier in await monitor.identifiers {
                try await stopMonitoringRegion(habitIdentifier: identifier)
            }
        }
        print("🔎🛑✅ CL MONITOR All regions are being removed")
    }

    func manageRegions(currentLocation: CLLocation) async throws -> Double {
        var habitsMonitored: [String] = []
        guard let (habits, distance): ([Habit], Double) = try? await habitsService.getHabitsByDistance(
            currentLocation: currentLocation,
            maxHabits: 5
        ) else {
            try await removeAllEvents()
            return 200
        }

        if let monitor {
            for identifier in await monitor.identifiers {
                guard let habitEntity = try await self.habitsService.getHabit(id: identifier) else {
                    try await stopMonitoringRegion(habitIdentifier: identifier)
                    return distance
                }

                if habits.contains(where: { $0.id.uuidString == identifier }) {
                    habitsMonitored.append(habitEntity.id.uuidString)
                } else {
                    try await stopMonitoringRegion(habitIdentifier: identifier, habitName: habitEntity.name)
                }
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
        print("\n **** Regions being monitored ****")
        if let monitor {
            for identifier in await monitor.identifiers {
                if let habit = try await self.habitsService.getHabit(id: identifier) {
                    print("► Name: \(habit.name)")
                } else {
                    print("► Identifier: \(identifier)")
                }
            }
        }
        print("\n **** End of Regions being monitored ****")
        // END OF DEBUG LOGS

        return distance
    }
}
