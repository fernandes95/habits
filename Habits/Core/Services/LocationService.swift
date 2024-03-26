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
    }

    func locationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

// TODO:
//    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String) {
//        // Make sure the devices supports region monitoring.
//        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//            // Register the region.
//            let maxDistance = self.locationManager.maximumRegionMonitoringDistance
//            let region = CLCircularRegion(center: center,
//                 radius: maxDistance, identifier: identifier)
//            region.notifyOnEntry = true
//            region.notifyOnExit = false
//
//            self.locationManager.startMonitoring(for: region)
//        }
//    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.status = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    // TODO:
//    private func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) async throws {
//        if let region = region as? CLCircularRegion {
//
//            try await notificationService.requestNotification(subTitle: "CHEGASTE AO LOCAL", date: Date.now)
//        }
//    }
}
