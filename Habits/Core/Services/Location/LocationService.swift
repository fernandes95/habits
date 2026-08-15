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
    private let habitsService: HabitsService
    private var regionService: RegionService?
    private var locationManager: CLLocationManager = CLLocationManager()
    private var backgroundSession: CLBackgroundActivitySession?
    private let regionRadius: CLLocationDistance = 100
    private var didRunInitialInsideCheck = false

    @Published
    var status: CLAuthorizationStatus?

    // desiredAccuracy as kCLLocationAccuracyBestForNavigation to have the most accurate location
    // activityType as otherNavigation to include all type of navigation besides airborn
    init(habitsService: HabitsService) {
        self.habitsService = habitsService
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = self.regionRadius
        self.locationManager.activityType = .otherNavigation
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.regionService = RegionServiceImpl(habitsService: habitsService, regionRadius: self.regionRadius)
    }

    func startTrackingWithBackgroundSupport() {
        didRunInitialInsideCheck = false
        self.backgroundSession = CLBackgroundActivitySession()
        self.locationManager.startUpdatingLocation()
    }

    func requestOneTimeLocation() {
        self.locationManager.requestLocation()
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
            self.startTrackingWithBackgroundSupport()   // sets didRunInitialInsideCheck = false
            self.requestOneTimeLocation()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            self.stopUpdatingLocation()
        case .notDetermined:
            break
        default:
            break
        }
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
        guard let location = locations.first else { return }
        Task {
            if !self.didRunInitialInsideCheck {
                self.didRunInitialInsideCheck = true
                try? await self.regionService?.checkAlreadyInsideRegion(currentLocation: location)
            }
            guard let distance = try await self.regionService?.manageRegions(currentLocation: location) else { return }
            self.setDistanceFilter(distance: distance)
        }
        Logger.location.debug("Regions being monitored count: \(manager.monitoredRegions.count)")
    }

    /// Handles failure when getting a user’s location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.location.debug("ERROR: \(error.localizedDescription)")
    }
}
