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
        self.didRunInitialInsideCheck = false
        self.backgroundSession = CLBackgroundActivitySession()
        self.locationManager.startUpdatingLocation()
    }

    func requestOneTimeLocation() {
        let status = self.locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        self.locationManager.requestLocation()
    }

    func stopUpdatingLocation() {
        self.backgroundSession?.invalidate()
        self.backgroundSession = nil
        self.locationManager.stopUpdatingLocation()
    }

    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return self.locationManager.authorizationStatus
    }

    /// Request Location Authorization `Always`
    func requestLocationAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
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
            try await self.regionService?.monitorRegion(
                center: location,
                habitIdentifier: habitIdentifier,
                habitName: habitName
            )
        }
    }

    /// Stops Monitoring Region by identifier
    ///
    /// - Parameter identifier: Location Identifier
    func stopMonitoringRegion(habitIdentifier: String, habitName: String) {
        Task {
            try await self.regionService?.stopMonitoringRegion(habitIdentifier: habitIdentifier, habitName: habitName)
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

    /// Gets Location updates and manages regions based on current Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task {
            if !self.didRunInitialInsideCheck {
                self.didRunInitialInsideCheck = true
                try? await self.regionService?.checkAlreadyInsideRegion(currentLocation: location)
            }
        }
        Logger.location.debug("Regions being monitored count: \(manager.monitoredRegions.count)")
    }

    /// Handles failure when getting a user’s location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.location.debug("ERROR: \(error.localizedDescription)")
    }
}
