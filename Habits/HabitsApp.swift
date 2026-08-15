//
//  HabitsApp.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI
import OSLog

@main
struct HabitsApp: App {
    @UIApplicationDelegateAdaptor
    // swiftlint:disable:next unused_declaration
    private var appDelegate: AppDelegate

    @StateObject private var state: MainState
    @StateObject private var router: HabitsRouter = HabitsRouter()
    @Environment(\.scenePhase) var scenePhase

    init() {
        let habitsService = HabitsService()
        _state = StateObject(wrappedValue: MainState(habitsService: habitsService))
    }

    var body: some Scene {
        WindowGroup {

            // Bypassing normal app launch for Unit Testing
            if isProduction {
                ZStack {
                    self.router.root
                        .environmentObject(self.state)
                        .environmentObject(self.router)
                        .task {
                            await self.state.initHabits()
                            self.state.requestLocation()
                        }
                }
                .onDisappear()
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case ScenePhase.active:
                        self.state.forceStartUpdatingLocation()
                    default:
                        self.state.forceStopUpdatingLocation()
                    }
                }
            }
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
