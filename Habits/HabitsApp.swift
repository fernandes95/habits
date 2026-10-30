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
    @AppStorage("appLanguage") private var language: AppLanguage = .system

    @State private var showSplash: Bool = true

    init() {
        _state = StateObject(wrappedValue: MainState(environment: AppEnvironment.shared))
    }

    var body: some Scene {
        WindowGroup {

            // Bypassing normal app launch for Unit Testing
            if isProduction {
                ZStack {
                    RootTabView()
                        .environmentObject(self.state)
                        .task { await self.state.initHabits() }

                    if self.showSplash {
                        SplashView {
                            withAnimation(.easeOut(duration: 0.4)) {
                                self.showSplash = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)
                    }
                }
                .preferredColorScheme(theme.colorScheme)
                .environment(\.locale, language.locale)
            }
        }
        .onChange(of: self.scenePhase) { _, scenePhase in
            // Keeps the reminders going while the app isn't opened
            if scenePhase == .background && self.isProduction {
                AppEnvironment.shared.scheduleReminderRefresh()
            }
        }
        .backgroundTask(.appRefresh(AppEnvironment.reminderRefreshTaskId)) {
            await AppEnvironment.shared.refreshReminders()
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
