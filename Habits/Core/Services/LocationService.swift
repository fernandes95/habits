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
    private var locationManager: CLLocationManager = CLLocationManager()

    @Published
    var status: CLAuthorizationStatus?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 10
        self.locationManager.activityType = .otherNavigation
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
//        self.locationManager.stopUpdatingLocation()

        self.locationManager.startUpdatingLocation()
    }

    func locationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let region = CLCircularRegion(
                center: center,
                radius: 5,
                identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true

            self.locationManager.startMonitoring(for: region)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let message = "Changed location"

            Task {
                try await notificationService.requestInstantNotification(
                    subTitle: message
                )
            }
            print(message)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle failure to get a user’s location
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started monitoring region with IDENTIFIER: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            Task {
                try await notificationService.requestInstantNotification(
                    subTitle: "Entered region with IDENTIFIER: \(region.identifier)"
                )
            }
            print("Entered region with IDENTIFIER: \(region.identifier)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            Task {
                try await notificationService.requestInstantNotification(
                    subTitle: "Exited region with IDENTIFIER: \(region.identifier)"
                )
            }
            print("Exited region with IDENTIFIER: \(region.identifier)")
        }
    }
}
