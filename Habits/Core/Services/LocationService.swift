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
    private var regionService: RegionService?
    private var locationManager: CLLocationManager = CLLocationManager()

    @Published
    var status: CLAuthorizationStatus?

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

    func locationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

    func startMonitoringRegion(location: CLLocationCoordinate2D, identifier: String) {
        Task {
            try await regionService?.monitorRegion(center: location, identifier: identifier)
        }
    }

    func stopMonitoringRegion(identifier: String) {
        Task {
            try await regionService?.stopMonitoringRegion(identifier: identifier)
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

    private func setDistanceFilter(distance: Double) {
        let newDistance: Double =
        switch distance {
        case ...70:
            5.0
        case ...150:
            10.0
        case ...500:
            50.0
        default:
            200
        }

        self.locationManager.distanceFilter = newDistance

        print("New distance received: \(String(describing: distance))")
        print("New distance to set: \(newDistance)")
        print("Distance Filter: \(self.locationManager.distanceFilter)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("🏃🏻‍♂️‍➡️ Changed location")
            Task {
                guard let distance: Double = try await regionService?.manageRegions(currentLocation: location)
                else {
                    return
                }

                setDistanceFilter(distance: distance)
            }

            print(" Regions being monitored count: \(manager.monitoredRegions.count)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR: \(error.localizedDescription)")
        // Handle failure to get a user’s location
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("🔎✅ Started monitoring region with IDENTIFIER: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            print("⬆️ Entered region with IDENTIFIER: \(region.identifier)")
        }
    }

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
