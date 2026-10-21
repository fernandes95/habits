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
    @Environment(\.scenePhase) var scenePhase

    @AppStorage("appTheme") private var theme: AppTheme = .system

    init() {
        _state = StateObject(wrappedValue: MainState(environment: AppEnvironment.shared))
    }

    var body: some Scene {
        WindowGroup {

            // Bypassing normal app launch for Unit Testing
            if isProduction {
                RootTabView()
                    .environmentObject(self.state)
                    .task { await self.state.initHabits() }
                    .preferredColorScheme(theme.colorScheme)
            }
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
