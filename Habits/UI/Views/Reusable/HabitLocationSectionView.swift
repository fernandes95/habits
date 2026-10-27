//
//  HabitLocationSectionView.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/10/2026.
//

import SwiftUI

/// Form section with the habit location and the location reminder switch.
/// When notifications were denied the switch is disabled and a link to the notification settings is shown.
struct HabitLocationSectionView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject
    private var state: MainState

    @Binding
    var location: Habit.Location?

    @Binding
    var hasLocationReminder: Bool

    @Binding
    var place: LocationPlaceDetails?

    var isEditing: Bool = true

    /// Called when the location picker should be presented
    let onPickLocation: () -> Void

    @State
    private var isNotificationsDenied: Bool = false

    @State
    private var isResolvingPlace: Bool = false

    var body: some View {
        Section {
            if let location = self.location {
                LocationCardView(
                    location: location,
                    place: self.place,
                    isLoading: self.isResolvingPlace,
                    onTap: self.isEditing ? self.onPickLocation : nil,
                    onClear: self.isEditing ? self.clearLocation : nil
                )
                .listRowInsets(EdgeInsets())
            } else if self.isEditing {
                Button {
                    // Only prompts the first time, while the location permission wasn't asked yet
                    self.state.requestLocation()
                    self.onPickLocation()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location")
                            .font(.body.weight(.medium))
                        Text("habit_location_button")
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("new_habit_location")
            }

            Toggle("habit_has_location_reminder", isOn: self.$hasLocationReminder)
                .disabled(!self.isEditing || self.location == nil || self.isNotificationsDenied)
                .accessibilityIdentifier("new_habit_location_reminder")
                .onChange(of: self.hasLocationReminder) { _, hasLocationReminder in
                    if hasLocationReminder && self.isEditing {
                        self.requestNotificationsAuthorization()
                    }
                }
                .onAppear {
                    self.refreshNotificationsDenied()
                }
                .onChange(of: self.scenePhase) { _, scenePhase in
                    // Coming back from Settings, the notifications permission might have changed
                    if scenePhase == .active {
                        self.refreshNotificationsDenied()
                    }
                }

            if self.isEditing && self.isNotificationsDenied {
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        self.openURL(url)
                    }
                } label: {
                    HStack {
                        Text("general_open_settings")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .contentShape(.rect)
                }
                .accessibilityIdentifier("new_habit_open_notification_settings")
            }
        } header: {
            Text("habit_location_section_title")
        } footer: {
            if self.isEditing && self.isNotificationsDenied {
                Text("habit_location_notifications_denied")
            }
        }
        .task(id: self.resolvePlaceKey) {
            await self.resolvePlaceIfNeeded()
        }
    }

    /// Changes when the pin moves or the place is cleared, so a dropped pin gets its street looked up again
    private var resolvePlaceKey: String {
        guard let location = self.location else { return "" }
        return "\(location.latitude),\(location.longitude),\(self.place == nil)"
    }

    /// Dropped pins have no place name, look up the street once here so it's saved with the habit
    /// and the habits list never has to look it up
    private func resolvePlaceIfNeeded() async {
        guard let location = self.location, self.place == nil else {
            self.isResolvingPlace = false
            return
        }

        self.isResolvingPlace = true
        let place = await LocationPlaceDetails.resolve(latitude: location.latitude, longitude: location.longitude)
        // The pin moved or the section went away while looking it up
        guard !Task.isCancelled else { return }
        self.place = place
        self.isResolvingPlace = false
    }

    private func clearLocation() {
        withAnimation {
            self.location = nil
            self.hasLocationReminder = false
            self.place = nil
        }
    }

    /// Location reminders are delivered as notifications, the switch goes back off if they aren't allowed.
    /// Once notifications are allowed, asks for `Always` location, reminders fire in the background.
    /// One after the other, iOS only shows one permission alert at a time.
    private func requestNotificationsAuthorization() {
        Task {
            do {
                if try await !self.state.getNotificationsAuthorizationStatus() {
                    try await self.state.getNotificationsAuthorization()
                }

                if try await !self.state.getNotificationsAuthorizationStatus() {
                    withAnimation {
                        self.hasLocationReminder = false
                        self.isNotificationsDenied = self.state.notificationStatus == .denied
                    }
                    return
                }

                self.state.requestAlwaysLocation()
            } catch let error { print(error.localizedDescription) }
        }
    }

    private func refreshNotificationsDenied() {
        Task {
            do {
                let isAuthorized: Bool = try await self.state.getNotificationsAuthorizationStatus()
                withAnimation {
                    self.isNotificationsDenied = !isAuthorized && self.state.notificationStatus == .denied
                }
            } catch let error { print(error.localizedDescription) }
        }
    }
}
