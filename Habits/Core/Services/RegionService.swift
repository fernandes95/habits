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
    private var locationManager: CLLocationManager?

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
