//
//  RegionService.swift
//  Habits
//
//  Created by Tiago Fernandes on 10/04/2024.
//

import Foundation
import CoreLocation

protocol RegionService {
    func monitorRegion(center: CLLocationCoordinate2D, identifier: String) async
    func stopMonitoringRegion(identifier: String) async
    func validateRegion(identifier: String) async throws -> Bool
    func manageRegions(currentLocation: CLLocation) async throws
}
