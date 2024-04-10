//
//  DefaultRegionService.swift
//  Habits
//
//  Created by Tiago Fernandes on 10/04/2024.
//

import Foundation
import CoreLocation

enum BackwardsCompactability {
    static func regionService(locationManager: CLLocationManager) -> RegionService {
        return if #available(iOS 17.0, *) {
            RegionServiceNew()
        } else {
            RegionServiceOld(locationManager: locationManager)
        }
    }
}
