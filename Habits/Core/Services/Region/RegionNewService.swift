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
                    print("⬆️ CL MONITOR ENTERED REGION")
                    try await remindUser(id: event.identifier)
                case .unknown, .unsatisfied: // callback when user EXITS any of the registered regions.
                    print("⬇️ CL MONITOR EXITED REGION")
                    if try await validateRegion(identifier: event.identifier) {
                        try await stopMonitoringRegion(identifier: event.identifier)
                    }
                default:
                    print("CL MONITOR No Location Registered")
                }
        }
    }

    private func remindUser(id: String) async throws {
        guard let habitName: String = try await self.habitsService.getHabit(id: id)?.name else {
            try await stopMonitoringRegion(identifier: id)
            return
        }

        try await notificationService.requestInstantNotification(subTitle: "Don't forget to: \(habitName)")
    }

    func monitorRegion(center: CLLocationCoordinate2D, identifier: String) async throws {
        let habitName: String = try await self.habitsService.getHabit(id: identifier)?.name ?? ""

        // making sure to remove if habit is being updated
        // CLMonitor.add doesn't update if it exists
        try await stopMonitoringRegion(identifier: identifier)
        await monitor?.add(
            CLMonitor.CircularGeographicCondition(center: center, radius: 5),
            identifier: identifier,
            assuming: .unsatisfied
        )
        print("🔎✅ CL MONITOR Started monitoring region for HABIT: \(habitName)")
    }

    func stopMonitoringRegion(identifier: String) async throws {
        let habitName: String = try await self.habitsService.getHabit(id: identifier)?.name ?? ""

        await monitor?.remove(identifier)
        print("🔎🛑 CL MONITOR Stoped monitoring region for HABIT: \(habitName)")
    }

    func validateRegion(identifier: String) async throws -> Bool {
        guard let habits: [Habit] = try? await habitsService.loadCheckedHabits(date: Date.now) else { return false }

        let habitIsChecked = habits.first(where: { $0.id.uuidString == identifier })?.isChecked

        return habitIsChecked ?? false
    }

    private func removeAllEvents() async throws {
        if let monitor {
            for identifier in await monitor.identifiers {
                try await stopMonitoringRegion(identifier: identifier)
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
                    try await stopMonitoringRegion(identifier: identifier)
                    return distance
                }

                let habit: Habit = Habit(habitEntity: habitEntity)

                if !habits.contains(where: { $0.id.uuidString == identifier }) {
                    try await stopMonitoringRegion(identifier: identifier)
                } else {
                    habitsMonitored.append(habit.id.uuidString)
                }
            }
        }

        for habit in habits where !habitsMonitored.contains(where: { $0 == habit.id.uuidString }) {
            try await monitorRegion(center: habit.location!.locationCoordinate, identifier: habit.id.uuidString)
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
