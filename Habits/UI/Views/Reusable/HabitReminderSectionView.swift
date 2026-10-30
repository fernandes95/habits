//
//  HabitReminderSectionView.swift
//  Habits
//
//  Created by Tiago Fernandes on 29/10/2026.
//

import SwiftUI

/// Form section with the reminder switch and the hours it reminds at.
/// Turning it on asks for notifications. When they were denied the hours stay editable and saved,
/// a note and a link to the notification settings are shown instead.
struct HabitReminderSectionView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale

    @EnvironmentObject
    private var state: MainState

    @Binding
    var habit: Habit

    var isEditing: Bool = true

    @State
    private var isNotificationsDenied: Bool = false

    var body: some View {
        Section {
            Toggle("habit_reminder", isOn: self.$habit.hasAlarm)
                .disabled(!self.isEditing)
                .accessibilityIdentifier("habit_reminder")
                .onChange(of: self.habit.hasAlarm) { _, hasAlarm in
                    guard hasAlarm && self.isEditing else { return }
                    if self.habit.schedule.isEmpty {
                        self.addHour()
                    }
                    self.requestNotificationsAuthorization()
                }

            if self.habit.hasAlarm {
                if self.isNotificationsDenied {
                    self.deniedRow
                    self.openSettingsButton
                }

                ForEach(self.$habit.schedule) { $hour in
                    if let index = self.habit.schedule.firstIndex(of: hour) {
                        DatePicker("habit_schedule_hour \(index + 1)",
                                   selection: $hour.date,
                                   displayedComponents: .hourAndMinute
                        )
                        // On touch down, before the picker opens and remembers the focused field
                        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in self.dismissKeyboard() })
                        // Still editable, it only tells the times won't remind yet
                        .opacity(self.isNotificationsDenied ? 0.5 : 1)
                        .swipeActions(edge: .trailing) {
                            // The reminder needs at least one hour, the switch turns it off instead
                            if self.isEditing && self.habit.schedule.count > 1 {
                                Button(role: .destructive) {
                                    self.habit.schedule.remove(at: index)
                                } label: {
                                    Label("habit_schedule_delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .disabled(!self.isEditing)

                if self.isEditing {
                    Button {
                        self.dismissKeyboard()
                        self.addHour()
                    } label: {
                        Label("habit_reminder_add_time", systemImage: "plus")
                    }
                    .accessibilityLabel("habits_accessibility_new_schedule_hour")
                }
            }
        } footer: {
            self.footer
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
    }

    private var deniedRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.subheadline)
                .foregroundStyle(Color.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.2), in: .rect(cornerRadius: 8))
                .accessibilityHidden(true)

            Text("habit_reminder_notifications_denied")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var openSettingsButton: some View {
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
        .accessibilityIdentifier("habit_reminder_open_notification_settings")
    }

    @ViewBuilder
    private var footer: some View {
        if !self.habit.hasAlarm {
            Text("habit_reminder_off_hint")
        } else if self.isNotificationsDenied {
            Text("habit_reminder_denied_hint")
        } else if let times = self.formattedTimes {
            Text("habit_reminder_on_hint \(times)")
        }
    }

    /// Reminder hours in time order, like "09:00, 13:00 and 19:00"
    private var formattedTimes: String? {
        let times = self.habit.reminderHours.map {
            // Two digit hour, same as the hour pickers
            $0.date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits).locale(self.locale))
        }
        guard !times.isEmpty else { return nil }
        return times.formatted(.list(type: .and).locale(self.locale))
    }

    /// First hour is 09:00 of the start date, the next ones an hour after the latest one
    private func addHour() {
        let calendar = Calendar.current
        let latest = self.habit.schedule.max { $0.minutesOfDay < $1.minutesOfDay }
        let date: Date? = if let latest {
            calendar.date(byAdding: .hour, value: 1, to: latest.date)
        } else {
            calendar.date(bySettingHour: 9, minute: 0, second: 0, of: self.habit.startDate)
        }

        self.habit.schedule.append(Hour(eventId: "", date: date ?? .now))
    }

    /// Asks for notifications the first time. The switch stays on when they're denied,
    /// the hours are saved and remind once notifications are allowed.
    private func requestNotificationsAuthorization() {
        Task {
            do {
                if try await !self.state.getNotificationsAuthorizationStatus() {
                    try await self.state.getNotificationsAuthorization()
                }
                self.refreshNotificationsDenied()
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

    /// Removes the focus from any text field. The hour picker gives the focus back to
    /// the last focused field when it closes, so it has to be cleared before it opens.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
