//
//  AppEnvironment.swift
//  Habits
//
//  Created by Tiago Fernandes on 07/09/2026.
//

import Foundation
import CoreLocation

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let habitsService: HabitsService
    let regionService: RegionServiceImpl
    let locationService: LocationService

    private init() {
        let habitsService = HabitsService()
        let regionService = RegionServiceImpl(habitsService: habitsService, regionRadius: 100)

        self.habitsService = habitsService
        self.regionService = regionService
        self.locationService = LocationService(
            habitsService: habitsService,
            regionService: regionService
        )
    }

    func regionMonitoring() {
        Task {
            try? await self.habitsService.load()
            try? await self.regionService.startMonitoringIfAuthorized()
            self.locationService.requestOneTimeLocation()
        }
    }
}
