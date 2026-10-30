//
//  HabitsView+Reminders.swift
//  Habits
//
//  Created by Tiago Fernandes on 30/10/2026.
//

import SwiftUI

// MARK: Reminders paused
extension HabitsView {
    /// One banner for the reminders that can't remind. With notifications and `Always` location
    /// both off it's a single banner, each habit counted once, instead of two stacked banners
    @ViewBuilder
    var remindersPausedBanner: some View {
        let notificationsPaused = self.state.pausedNotificationReminders
        let locationPaused = self.state.pausedLocationReminders

        if !notificationsPaused.isEmpty && !locationPaused.isEmpty {
            let habitsCount = Set((notificationsPaused + locationPaused).map(\.id)).count
            AllRemindersPausedBanner(habitsCount: habitsCount)
        } else if !notificationsPaused.isEmpty {
            NotificationRemindersPausedBanner(habitsCount: notificationsPaused.count)
        } else if !locationPaused.isEmpty {
            LocationRemindersPausedBanner(habitsCount: locationPaused.count)
        }
    }

    /// Shown while habits have reminders that can't remind because a permission is missing,
    /// tells how many habits are affected and leads to the right Settings page
    internal struct RemindersPausedBanner: View {
        let systemImage: String
        let title: LocalizedStringKey
        let message: LocalizedStringKey
        /// Settings page where the missing permission is allowed
        let settingsURLString: String
        let settingsAccessibilityIdentifier: String

        @Environment(\.openURL) private var openURL

        var body: some View {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: self.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(Color.stepAccent)
                        .frame(width: 32, height: 32)
                        .background(Color.stepAccent.opacity(0.18), in: .circle)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(self.title)
                            .font(.subheadline.weight(.semibold))
                        Text(self.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    if let url = URL(string: self.settingsURLString) {
                        self.openURL(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("general_open_settings")
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill), in: .capsule)
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(self.settingsAccessibilityIdentifier)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            .accessibilityElement(children: .contain)
        }
    }

    /// Shown while habits have their location reminder on but `Always` location isn't allowed
    internal struct LocationRemindersPausedBanner: View {
        let habitsCount: Int

        var body: some View {
            RemindersPausedBanner(
                systemImage: "location.slash.fill",
                title: "habits_location_paused_title",
                message: "habits_location_paused_message \(self.habitsCount)",
                settingsURLString: UIApplication.openSettingsURLString,
                settingsAccessibilityIdentifier: "habits_location_paused_open_settings"
            )
        }
    }

    /// Shown while habits have time or location reminders but notifications aren't allowed
    internal struct NotificationRemindersPausedBanner: View {
        let habitsCount: Int

        var body: some View {
            RemindersPausedBanner(
                systemImage: "bell.slash.fill",
                title: "habits_notifications_paused_title",
                message: "habits_notifications_paused_message \(self.habitsCount)",
                settingsURLString: UIApplication.openNotificationSettingsURLString,
                settingsAccessibilityIdentifier: "habits_notifications_paused_open_settings"
            )
        }
    }

    /// Shown while notifications and `Always` location are both off and habits rely on them.
    /// The app's Settings page has both the notifications and the location rows
    internal struct AllRemindersPausedBanner: View {
        let habitsCount: Int

        var body: some View {
            RemindersPausedBanner(
                systemImage: "bell.slash.fill",
                title: "habits_notifications_paused_title",
                message: "habits_all_reminders_paused_message \(self.habitsCount)",
                settingsURLString: UIApplication.openSettingsURLString,
                settingsAccessibilityIdentifier: "habits_all_reminders_paused_open_settings"
            )
        }
    }
}

// MARK: Reminder hours
extension HabitsDayContentView {
    func hourChips(of habit: Habit, now: Date = .now) -> [Habit.HourChip] {
        habit.hourChips(on: self.selectedDate, now: now, selectedHourId: self.selectedHours[habit.id])
    }

    /// A tap on the checkbox does the selected hour, or a step of it with a goal.
    /// Without a selected hour, every hour left is missed, it does the first missed one.
    /// A done habit undoes its last hour
    func hourStatusTapped(_ habit: Habit) {
        if habit.isChecked {
            if let hourId = habit.lastCheckedHourId {
                onItemUncheckHourAction(habit, hourId)
            }
            return
        }

        let chips = self.hourChips(of: habit)
        guard let selected = chips.first(where: { $0.state == .selected })
                ?? chips.first(where: { $0.state == .missed }) else { return }

        // The picked missed hour stays selected while its steps are done
        let isHourDone = habit.goal.map { habit.completedCount + 1 >= $0.value } ?? true
        if isHourDone {
            self.selectedHours[habit.id] = nil
        }
        onItemCheckHourAction(habit, selected.id)
    }

    func hourTapped(_ chip: Habit.HourChip, of habit: Habit) {
        switch chip.state {
        case .done:
            // Undoing an hour of a complete habit undoes the habit too, it asks first
            if habit.isChecked {
                self.hourToReset = HourReset(habit: habit, chip: chip)
            } else {
                onItemUncheckHourAction(habit, chip.id)
            }
        case .missed:
            self.selectedHours[habit.id] = chip.id
        case .selected:
            // Picking a missed hour again leaves it missed
            if self.selectedHours[habit.id] == chip.id {
                self.selectedHours[habit.id] = nil
            }
        case .upcoming:
            break
        }
    }

    /// Steps done across every reminder hour out of the whole day, nil for habits without both a goal and hours.
    /// The ring still shows the steps of the hour being done
    func hoursGoalLabel(for habit: Habit) -> String? {
        guard let progress = habit.hoursGoalProgress else { return nil }
        return "\(progress.completed)/\(progress.total)"
    }
}

/// Hour the reset hour dialog asks about
struct HourReset {
    let habit: Habit
    let chip: Habit.HourChip
}

/// Asks before undoing a done hour of a complete habit, undoing it uncompletes the habit
struct HourResetAlert: ViewModifier {
    @Binding var reset: HourReset?
    let onReset: (HourReset) -> Void

    @Environment(\.locale) private var locale

    private var isPresented: Binding<Bool> {
        Binding(
            get: { self.reset != nil },
            set: { if !$0 { self.reset = nil } }
        )
    }

    func body(content: Content) -> some View {
        content
            .alert(
                Text("habit_hour_reset_dialog_title \(self.reset.map { self.time(of: $0.chip.hour) } ?? "")"),
                isPresented: self.isPresented,
                presenting: self.reset
            ) { reset in
                Button("habit_hour_reset_dialog_reset", role: .destructive) {
                    self.onReset(reset)
                }
                Button("general_cancel", role: .cancel) { }
            } message: { reset in
                Text("habit_hour_reset_dialog_message \(reset.habit.name)")
            }
    }

    /// Two digit hour, same as the hour chips
    private func time(of hour: Hour) -> String {
        hour.date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits).locale(self.locale))
    }
}
