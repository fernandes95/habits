//
//  RegionServiceOld.swift
//  Habits
//
//  Created by Tiago Fernandes on 10/04/2024.
//

import Foundation
import CoreLocation

class RegionServiceOld: RegionService {
    private let habitsService: HabitsService = HabitsService()
    private var locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }

    func monitorRegion(center: CLLocationCoordinate2D, identifier: String) async {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let region = CLCircularRegion(
                center: center,
                radius: 5,
                identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true

            self.locationManager.startMonitoring(for: region)
            self.locationManager.startUpdatingLocation()
        }
    }

    func stopMonitoringRegion(identifier: String) async {
        if let region = self.locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            self.locationManager.stopMonitoring(for: region)
        }
    }

    func validateRegion(identifier: String) async throws -> Bool {
        guard let habits: [Habit] = try? await habitsService.loadCheckedHabits(date: Date.now) else { return false }

        let habitIsChecked = habits.first(where: { $0.id.uuidString == identifier })?.isChecked

        return habitIsChecked ?? false
    }

    func manageRegions(currentLocation: CLLocation) async throws {
        guard let habits: [Habit] =
                try? await habitsService.getHabitsByDistance(currentLocation: currentLocation) else {
                for region in self.locationManager.monitoredRegions {
                    self.locationManager.stopMonitoring(for: region)
                    }
                return
            }

        let regions: [CLCircularRegion] = habits
            .map { habit in
                return CLCircularRegion(
                    center: habit.location!.locationCoordinate,
                    radius: 5,
                    identifier: habit.id.uuidString
                )
            }

        return
    }
}
