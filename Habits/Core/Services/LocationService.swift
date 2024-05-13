//
//  LocationService.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/03/2024.
//

import Foundation
import MapKit
import CoreLocation

class LocationService: NSObject, ObservableObject {
    private let notificationService: NotificationService = NotificationService()
    private let habitsService: HabitsService = HabitsService()
    private var regionService: RegionService?
    private var locationManager: CLLocationManager = CLLocationManager()

    @Published
    var status: CLAuthorizationStatus?

    // desiredAccuracy as kCLLocationAccuracyBestForNavigation to have the most accurate location
    // activityType as otherNavigation to include all type of navigation besides airborn
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 5
        self.locationManager.activityType = .otherNavigation
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.startUpdatingLocation()
        self.regionService = BackwardsCompactability.regionService(locationManager: self.locationManager)
    }

    /// Request Location Authorization `When In Use`
    func locationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

    /// Updates Location
    ///
    /// Forces to stop location, go to minimum distance filter an then force start update location again
    private func forceUpdateLocation() {
        self.locationManager.stopUpdatingLocation()
        self.locationManager.distanceFilter = 1
        self.locationManager.startUpdatingLocation()
    }

    /// Starts Monitoring Region
    ///
    /// - Parameters:
    ///   - location: Precise location to start monitoring
    ///   - identifier: Location Identifier
    func startMonitoringRegion(location: CLLocationCoordinate2D, identifier: String) {
        Task {
            try await regionService?.monitorRegion(center: location, identifier: identifier)
            self.forceUpdateLocation()
        }
    }

    /// Stops Monitoring Region by identifier
    ///
    /// - Parameter identifier: Location Identifier
    func stopMonitoringRegion(identifier: String) {
        Task {
            try await regionService?.stopMonitoringRegion(identifier: identifier)
            self.forceUpdateLocation()
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    /// Handles Location Manager Authorization changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus = manager.authorizationStatus
        self.status = status

        switch status {
        case .authorizedAlways:
            // Handle case
            return
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .denied:
            // Handle case
            return
        case .notDetermined:
            // Handle case
            return
        case .restricted:
            // Handle case
            return
        default:
            return
        }
    }

    /// Sends Instant Notification to Remind User and stops monitoring region by Habit ID
    ///
    /// - Parameter id: Habit ID
    private func remindUser(id: String) async throws {
        guard let habitName: String = try await self.habitsService.getHabit(id: id)?.name else {
            try await self.regionService?.stopMonitoringRegion(identifier: id)
            return
        }

        try await notificationService.requestInstantNotification(subTitle: "Dont forget to: \(habitName)")
    }

    /// Sets new distance filter to Location Manager based on `Distance` paramether
    ///
    /// - Parameter distance: Distance to filter
    private func setDistanceFilter(distance: Double) {
        let newDistance: Double =
            switch distance {
            case ...70:
                5
            case ...150:
                10
            case ...500:
                50
            default:
                200
            }

        self.locationManager.distanceFilter = newDistance

        print("\n New distance received: \(String(describing: distance))")
        print("New distance to set: \(newDistance)")
        print("Distance Filter: \(self.locationManager.distanceFilter)")
    }

    /// Gets Location updates and manages regions based on current Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("🏃🏻‍♂️‍➡️ Changed location")
            Task {
                guard let distance: Double = try await regionService?.manageRegions(currentLocation: location)
                else {
                    return
                }

                self.setDistanceFilter(distance: distance)
            }

            print(" Regions being monitored count: \(manager.monitoredRegions.count)")
        }
    }

    /// Handles failure when getting a user’s location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR: \(error.localizedDescription)")
    }

    /// Logs when region monitoring starts to a specific identifier
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("🔎✅ Started monitoring region with IDENTIFIER: \(region.identifier)")
    }

    /// Handles user entering region and reminds user
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            print("⬆️ Entered region with IDENTIFIER: \(region.identifier)")
            Task {
                try await self.remindUser(id: region.identifier)
            }
        }
    }

    /// Handles user exiting region.
    /// If the user checks the Habit as done it will stop monitoring said region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            print("⬇️ Exited region with IDENTIFIER: \(region.identifier)")
            Task {
                if try await regionService?.validateRegion(identifier: region.identifier) ?? false {
                        locationManager.stopMonitoring(for: region)
                    print("🔎🛑 Stoped monitoring region: \(region.identifier)")
                }
            }
        }
    }
}
