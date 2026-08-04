//
//  LocationService.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/03/2024.
//

import Foundation
import MapKit
import CoreLocation
import OSLog

class LocationService: NSObject, ObservableObject {
    private let notificationService: NotificationService = NotificationService()
    private let habitsService: HabitsService = HabitsService()
    private var regionService: RegionService?
    private var locationManager: CLLocationManager = CLLocationManager()
    private var backgroundSession: CLBackgroundActivitySession?

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
        self.regionService = RegionServiceImpl()
    }

    func startTrackingWithBackgroundSupport() {
        self.backgroundSession = CLBackgroundActivitySession()
        self.locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        backgroundSession?.invalidate()
        backgroundSession = nil
        self.locationManager.stopUpdatingLocation()
    }

    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return self.locationManager.authorizationStatus
    }

    /// Request Location Authorization `When In Use`
    func locationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

    /// Updates Location
    ///
    /// Forces to stop location, go to minimum distance filter an then force start update location again
    func forceUpdateLocation() {
        self.locationManager.stopUpdatingLocation()
        self.locationManager.distanceFilter = 1
        self.locationManager.startUpdatingLocation()
    }

    /// Starts Monitoring Region
    ///
    /// - Parameters:
    ///   - location: Precise location to start monitoring
    ///   - identifier: Location Identifier
    func startMonitoringRegion(
        location: CLLocationCoordinate2D,
        habitIdentifier: String,
        habitName: String,
    ) {
        Task {
            try await regionService?.monitorRegion(
                center: location,
                habitIdentifier: habitIdentifier,
                habitName: habitName
            )
            self.forceUpdateLocation()
        }
    }

    /// Stops Monitoring Region by identifier
    ///
    /// - Parameter identifier: Location Identifier
    func stopMonitoringRegion(habitIdentifier: String, habitName: String) {
        Task {
            try await regionService?.stopMonitoringRegion(habitIdentifier: habitIdentifier, habitName: habitName)
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
            try await self.regionService?.stopMonitoringRegion(habitIdentifier: id, habitName: nil)
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

        Logger.location.debug("\n New distance received: \(String(describing: distance))")
        Logger.location.debug("New distance to set: \(newDistance)")
        Logger.location.debug("Distance Filter: \(self.locationManager.distanceFilter)")
    }

    /// Gets Location updates and manages regions based on current Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            Logger.location.debug("🏃🏻‍♂️‍➡️ Changed location")
            Task {
                guard let distance: Double = try await regionService?.manageRegions(currentLocation: location)
                else {
                    return
                }

                self.setDistanceFilter(distance: distance)
            }

            Logger.location.debug("Regions being monitored count: \(manager.monitoredRegions.count)")
        }
    }

    /// Handles failure when getting a user’s location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.location.debug("ERROR: \(error.localizedDescription)")
    }

    /// Logs when region monitoring starts to a specific identifier
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Logger.location.debug("🔎✅ Started monitoring region with IDENTIFIER: \(region.identifier)")
    }

    /// Handles user entering region and reminds user
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            Logger.location.debug("⬆️ Entered region with IDENTIFIER: \(region.identifier)")
            Task {
                try await self.remindUser(id: region.identifier)
            }
        }
    }

    /// Handles user exiting region.
    /// If the user checks the Habit as done it will stop monitoring said region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            Logger.location.debug("⬇️ Exited region with IDENTIFIER: \(region.identifier)")
            Task {
                if try await regionService?.validateRegion(identifier: region.identifier) ?? false {
                        locationManager.stopMonitoring(for: region)
                    Logger.location.debug("🔎🛑 Stoped monitoring region: \(region.identifier)")
                }
            }
        }
    }
}
