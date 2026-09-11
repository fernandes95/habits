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

    @StateObject private var state: MainState = StateObject(wrappedValue: MainState(environment: .shared)).wrappedValue
    @StateObject private var router: HabitsRouter = HabitsRouter()
    @Environment(\.scenePhase) var scenePhase

    init() {
        _state = StateObject(wrappedValue: MainState(environment: AppEnvironment.shared))
    }

    var body: some Scene {
        WindowGroup {

            // Bypassing normal app launch for Unit Testing
            if isProduction {
                ZStack {
                    self.router.root
                        .environmentObject(self.state)
                        .environmentObject(self.router)
                        .task { await self.state.initHabits() }
                }
                .onDisappear()
            }
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
