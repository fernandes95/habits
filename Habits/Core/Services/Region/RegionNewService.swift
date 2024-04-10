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
                case .unknown, .unsatisfied: // callback when user EXITS any of the registered regions.
                    print("⬇️ CL MONITOR EXITED REGION")
                    if try await validateRegion(identifier: event.identifier) {
                        await stopMonitoringRegion(identifier: event.identifier)
                    }

                default:
                    print("CL MONITOR No Location Registered")
                }
        }
    }

    func monitorRegion(center: CLLocationCoordinate2D, identifier: String) async {
        await monitor?.add(
            CLMonitor.CircularGeographicCondition(center: center, radius: 5),
            identifier: identifier,
            assuming: .unsatisfied
        )

        // FIXME: fix this
        var habitName: String = ""
        do {
            habitName = try await habitsService.getHabit(id: identifier)?.name ?? ""
        } catch {}
        print("🔎✅ CL MONITOR Started monitoring region for HABIT: \(habitName)")
    }

    func stopMonitoringRegion(identifier: String) async {
        await monitor?.remove(identifier)

        // FIXME: fix this
        var habitName: String = ""
        do {
            habitName = try await habitsService.getHabit(id: identifier)?.name ?? ""
        } catch {}
        print("🔎🛑 CL MONITOR Started monitoring region for HABIT: \(habitName)")
    }

    func validateRegion(identifier: String) async throws -> Bool {
        guard let habits: [Habit] = try? await habitsService.loadCheckedHabits(date: Date.now) else { return false }

        let habitIsChecked = habits.first(where: { $0.id.uuidString == identifier })?.isChecked

        return habitIsChecked ?? false
    }

    // TODO: REMOVING ALL NOT WORKING BECAUSE ASYNC
    private func removeAllEvents() async throws {
        if let monitor {
            for try await event in await monitor.events {
                await monitor.remove(event.identifier)
            }
        }
    }

    func manageRegions(currentLocation: CLLocation) async throws {
        guard let habits: [Habit] = try? await habitsService.getHabitsByDistance(
            currentLocation: currentLocation
        ) else {
            try await removeAllEvents()
            return
        }

        // delete all events before adding all again
        try await removeAllEvents()

        for habit in habits {
            await monitorRegion(center: habit.location!.locationCoordinate, identifier: habit.id.uuidString)
        }

            // DEBUG LOGS
//            print("\n **** Regions being monitored ****")
//            for event in events {
//                let habitName: String = try await self.habitsService.getHabit(id: event.identifier)?.name ?? ""
//                print("► Name: \(habitName)")
//                return event
//            }
//            print("\n **** End of Regions being monitored ****")
            // END OF DEBUG LOGS
    }
}
