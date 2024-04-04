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
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
        self.status = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started monitoring region with IDENTIFIER: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
//            Task {
//                try await notificationService.requestInstantNotification(
//                    subTitle: "Entered region with IDENTIFIER: \(region.identifier)"
//                )
//            }
            print("Entered region with IDENTIFIER: \(region.identifier)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
//            Task {
//                try await notificationService.requestInstantNotification(
//                    subTitle: "Exited region with IDENTIFIER: \(region.identifier)"
//                )
//            }
            print("Exited region with IDENTIFIER: \(region.identifier)")
        }
    }
}
