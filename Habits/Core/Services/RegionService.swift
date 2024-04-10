//
//  RegionService.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/04/2024.
//

import Foundation
import CoreLocation

class RegionService {
    private var habitsService: HabitsService = HabitsService()

    func monitorRegion(locationManager: CLLocationManager, center: CLLocationCoordinate2D, identifier: String) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let region = CLCircularRegion(
                center: center,
                radius: 5,
                identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true

            locationManager.startMonitoring(for: region)
            locationManager.startUpdatingLocation()
        }
    }

    func stopMonitoringRegion(locationManager: CLLocationManager, identifier: String) {
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: region)
        }
    }

    func validateRegion(identifier: String) async throws -> Bool {
        guard let habits: [Habit] = try? await habitsService.loadCheckedHabits(date: Date.now) else { return false }

        let habitIsChecked = habits.first(where: { $0.id.uuidString == identifier })?.isChecked

        return habitIsChecked ?? false
    }

    func manageRegions(currentLocation: CLLocation) async throws -> [CLCircularRegion] {
        guard let habits: [Habit] = try? await habitsService.loadUncheckedHabits(date: Date.now) else { return [] }

        let habitsByDistance: [Habit] = habits
            .filter({ $0.location != nil })
            .sorted { (lhs: Habit, rhs: Habit) in
                let lhsLocation: CLLocation = CLLocation(
                    latitude: lhs.location!.latitude,
                    longitude: lhs.location!.longitude
                )
                let rhsLocation: CLLocation = CLLocation(
                    latitude: rhs.location!.latitude,
                    longitude: rhs.location!.longitude
                )

                return currentLocation.distance(from: lhsLocation) < currentLocation.distance(from: rhsLocation)
            }

        let regions: [CLCircularRegion] = habitsByDistance
            .map { habit in
                return CLCircularRegion(
                    center: habit.location!.locationCoordinate,
                    radius: 5,
                    identifier: habit.id.uuidString
                )
            }

        // for testing purposes
        for habit in habitsByDistance {
            let closestLocation: CLLocation = CLLocation(
                latitude: habit.location!.latitude,
                longitude: habit.location!.longitude
            )
            let distance = currentLocation.distance(from: closestLocation)
            print("Name: \(habit.name) \n Distance: \(distance)")
        }

        return regions
    }
}
