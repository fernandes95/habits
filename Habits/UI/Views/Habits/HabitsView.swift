//
//  ContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI
import CoreLocation

struct HabitsView: View {
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    var state: MainState

    @State private var didLoadData = false

    @State private var showNewHabitSheet = false

    @State private var viewMode: ViewMode = .today

    var body: some View {
        VStack {
            Group {
                switch self.viewMode {
                case .today:
                    TodayHeaderView(date: self.state.selectedDate)
                case .week:
                    WeekHeaderView(
                        date: self.$state.selectedDate,
                        progress: self.state.dayProgress,
                        calendar: self.state.calendar,
                        earliestDate: self.state.configs.earliestDate,
                        changeDateAction: self.loadSelectedDate
                    )
                case .all:
                    AllHabitsHeaderView()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // No close button, it stays until the missing permissions are allowed again
            self.remindersPausedBanner
                .padding(.horizontal)
                .padding(.bottom, 12)
                .transition(.opacity)

            ZStack(alignment: .bottomTrailing) {
                switch self.viewMode {
                case .today:
                    self.dayContent
                case .week:
                    DaySwipeContainer(canSwipe: self.canChangeDay, onSwipe: changeDay) {
                        self.dayContent
                    }
                case .all:
                    AllHabitsContentView(
                        list: self.state.allHabits,
                        isEmptyStateVisible: self.state.didLoadHabits && self.state.allHabits.isEmpty,
                        distance: self.state.distance(to:),
                        isLocationReminderPaused: self.state.isLocationReminderPaused,
                        isNotificationReminderPaused: self.state.isNotificationReminderPaused,
                        onItemAction: { habit in
                            router.push(HabitDetailView(habit: habit))
                        }
                    )
                }
            }
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                self.modeMenu
            }
        }
        .onChange(of: self.viewMode) { _, newMode in
            // Today always shows the current day, even if another day was picked in the week view
            if newMode == .today && !Calendar.current.isDateInToday(self.state.selectedDate) {
                self.selectToday()
            }
        }
        .onChange(of: self.scenePhase) { _, scenePhase in
            // The user may have moved while the app was in the background
            if scenePhase == .active {
                self.state.refreshCurrentLocation()
                // Notifications may have been allowed in Settings, and the reminder days move forward
                Task { await self.state.syncReminders() }
            }
        }
        .task {
            if !didLoadData {
                self.reloadAll()
                didLoadData = true
            }
        }
    }

    private var dayContent: some View {
        HabitsDayContentView(
            list: self.$state.habits,
            isEmptyStateVisible: self.state.didLoadHabits && self.state.allHabits.isEmpty,
            selectedDate: self.state.selectedDate,
            calendar: self.state.calendar,
            distance: self.state.distance(to:),
            isLocationReminderPaused: self.state.isLocationReminderPaused,
            isNotificationReminderPaused: self.state.isNotificationReminderPaused,
            onItemStatusAction: { habit in
                Task {
                    do {
                        try await self.state.updateHabit(habit: habit)
                    } catch let error { print(error.localizedDescription) }
                }
            },
            onItemUndoStepAction: { habit in
                Task {
                    do {
                        try await self.state.undoLastStep(habit: habit)
                    } catch let error { print(error.localizedDescription) }
                }
            },
            onItemResetAction: { habit in
                Task {
                    do {
                        try await self.state.resetProgress(habit: habit)
                    } catch let error { print(error.localizedDescription) }
                }
            },
            onItemCheckHourAction: { habit, hourId in
                Task {
                    do {
                        try await self.state.checkHour(habit: habit, hourId: hourId)
                    } catch let error { print(error.localizedDescription) }
                }
            },
            onItemUncheckHourAction: { habit, hourId in
                Task {
                    do {
                        try await self.state.uncheckHour(habit: habit, hourId: hourId)
                    } catch let error { print(error.localizedDescription) }
                }
            },
            onItemAction: { habit in
                router.push(HabitDetailView(habit: habit))
            }
        )
    }

    private var modeMenu: some View {
        Menu {
            Picker("habits_accessibility_view_mode", selection: self.$viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
        } label: {
            Image(systemName: self.viewMode.systemImage)
        }
        .accessibilityLabel("habits_accessibility_view_mode")
    }

    private func selectToday() {
        Task {
            do {
                try await state.selectDate(.now)
            } catch let error { print(error.localizedDescription) }
        }
    }

    /// Day changed from the header (day tap, week swipe, calendar)
    private func loadSelectedDate() {
        Task {
            do {
                try await state.selectDate(state.selectedDate)
            } catch let error { print(error.localizedDescription) }
        }
    }

    /// Full load of the block around the selected date
    private func reloadAll() {
        Task {
            do {
                try await state.loadHabits(date: state.selectedDate)
            } catch let error { print(error.localizedDescription) }
        }
    }

    /// False when moving by `days` goes before the earliest date
    private func canChangeDay(by days: Int) -> Bool {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: state.selectedDate) else { return false }
        return newDate.startOfDay >= self.state.configs.earliestDate
    }

    /// Moves the selected date by `days` (negative goes back) and waits until it's loaded
    private func changeDay(by days: Int) async {
        guard self.canChangeDay(by: days),
              let newDate = Calendar.current.date(byAdding: .day, value: days, to: state.selectedDate) else { return }
        do {
            try await state.selectDate(newDate, animated: false)
        } catch let error { print(error.localizedDescription) }
    }
}

/// Shown instead of the list when there are no habits at all
struct HabitsEmptyView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("habits_empty_title")
                .font(.title3.bold())
            Text("habits_empty_description")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Color {
    static let dayProgress = Color(red: 0.39, green: 0.77, blue: 0.39)
    static let dayTrack = Color(.systemGray5)
}

struct HabitsDayContentView: View {
    @Binding var list: [Habit]
    /// True when there are no habits at all, not just on this day
    var isEmptyStateVisible: Bool = false
    let selectedDate: Date
    /// Calendar with the configured first day of the week
    let calendar: Calendar
    /// Distance from the user to a habit location, nil while the user location is unknown
    let distance: (Habit.Location) -> CLLocationDistance?
    /// True when the habit's location reminder can't remind, `Always` location isn't allowed
    let isLocationReminderPaused: (Habit) -> Bool
    /// True when the habit's reminder hours can't remind, notifications aren't allowed
    let isNotificationReminderPaused: (Habit) -> Bool
    var onItemStatusAction: (Habit) -> Void
    var onItemUndoStepAction: (Habit) -> Void
    var onItemResetAction: (Habit) -> Void
    /// Does a reminder hour of the habit, or a step of it with a goal
    var onItemCheckHourAction: (Habit, UUID) -> Void
    /// Undoes a done reminder hour of the habit
    var onItemUncheckHourAction: (Habit, UUID) -> Void
    var onItemAction: (Habit) -> Void

    @Environment(\.scenePhase) private var scenePhase

    /// Done habit with a goal the user tapped, asks before changing its steps
    @State private var habitToReset: Habit?

    /// Done hour of a complete habit the user tapped, asks before undoing it
    @State var hourToReset: HourReset?

    /// Missed hour the user picked to do now, keyed by habit id.
    /// Only until the hour is done, picked again, or the app is left, the hour stays missed otherwise
    @State var selectedHours: [UUID: UUID] = [:]

    private var isResetDialogPresented: Binding<Bool> {
        Binding(
            get: { self.habitToReset != nil },
            set: { if !$0 { self.habitToReset = nil } }
        )
    }

    var body: some View {
        Group {
            if self.isEmptyStateVisible {
                HabitsEmptyView()
            } else {
                self.habitsList
            }
        }
        // Keeps the empty area swipeable when there are no habits
        .contentShape(Rectangle())
        .alert(
            Text("habit_reset_dialog_title \(self.habitToReset?.name ?? "")"),
            isPresented: self.isResetDialogPresented,
            presenting: self.habitToReset
        ) { habit in
            Button("habit_reset_dialog_undo") {
                onItemUndoStepAction(habit)
            }
            Button("habit_reset_dialog_reset", role: .destructive) {
                onItemResetAction(habit)
            }
            Button("general_cancel", role: .cancel) { }
        } message: { habit in
            self.resetMessage(for: habit)
        }
        .modifier(HourResetAlert(reset: self.$hourToReset) { reset in
            onItemUncheckHourAction(reset.habit, reset.chip.id)
        })
        .onChange(of: self.scenePhase) { _, scenePhase in
            if scenePhase != .active { self.selectedHours = [:] }
        }
        .onChange(of: self.selectedDate) {
            self.selectedHours = [:]
        }
    }

    private var habitsList: some View {
        List {
            ForEach($list) { $habit in
                let totalSteps = habit.goal?.value ?? 0
                let dividerColor = $list.count == 1 ?
                    Color.black.opacity(0.0) : nil

                // Hours turn missed as time goes by
                TimelineView(.everyMinute) { context in
                    ListItem(
                        name: habit.name,
                        completedSteps: habit.completedCount,
                        totalSteps: totalSteps,
                        label: self.minDaysLabel(for: habit) ?? self.hoursGoalLabel(for: habit),
                        location: habit.location,
                        locationDistance: habit.location.flatMap { self.distance($0) },
                        isLocationReminderPaused: self.isLocationReminderPaused(habit),
                        isNotificationReminderPaused: self.isNotificationReminderPaused(habit),
                        hasLocationReminder: habit.hasLocationReminder,
                        hourChips: self.hourChips(of: habit, now: context.date),
                        hourAction: { chip in self.hourTapped(chip, of: habit) },
                        status: $habit.isChecked,
                        statusAction: { self.statusTapped(habit) },
                        itemAction: { onItemAction(habit) }
                    )
                }
                .listItemRowInsets()
                .listRowSeparatorTint(dividerColor)
                // No divider above the first habit
                .listRowSeparator(habit.id == list.first?.id ? .hidden : .automatic, edges: .top)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func statusTapped(_ habit: Habit) {
        // Every step is done, one more tap would lose them all
        if habit.goal != nil && habit.isChecked {
            self.habitToReset = habit
            return
        }

        if !habit.reminderHours.isEmpty {
            self.hourStatusTapped(habit)
            return
        }

        var habit = habit
        habit.isChecked = !habit.isChecked
        onItemStatusAction(habit)
    }

    /// Steps logged out of the goal, on how many reminder hours, and which day the reset changes
    private func resetMessage(for habit: Habit) -> Text {
        let goal: Int = habit.goal?.value ?? 0
        let isToday: Bool = Calendar.current.isDateInToday(self.selectedDate)
        let day: String = self.selectedDate.formatted(.dateTime.day().month(.wide))

        let hours: Int = habit.reminderHours.count
        if hours > 0 {
            return isToday
                ? Text("habit_reset_dialog_hours_message_today \(habit.completedCount) \(goal) \(hours)")
                : Text("habit_reset_dialog_hours_message_day \(habit.completedCount) \(goal) \(hours) \(day)")
        }

        return isToday
            ? Text("habit_reset_dialog_message_today \(habit.completedCount) \(goal)")
            : Text("habit_reset_dialog_message_day \(habit.completedCount) \(goal) \(day)")
    }

    /// `checkedDays/minimumDays` for `.minDays` habits that reached the minimum in the selected week, nil otherwise
    private func minDaysLabel(for habit: Habit) -> String? {
        guard habit.hasReachedMinDays(inWeekOf: self.selectedDate, calendar: self.calendar) else { return nil }
        let checkedDays = habit.checkedDays(inWeekOf: self.selectedDate, calendar: self.calendar)
        return "\(checkedDays)/\(habit.frequencyType.minimumDays)"
    }
}

/// Every saved habit, without a status, only the name and the way to its detail
private struct AllHabitsContentView: View {
    let list: [Habit]
    /// True once the habits are loaded and there are none
    var isEmptyStateVisible: Bool = false
    /// Distance from the user to a habit location, nil while the user location is unknown
    let distance: (Habit.Location) -> CLLocationDistance?
    /// True when the habit's location reminder can't remind, `Always` location isn't allowed
    let isLocationReminderPaused: (Habit) -> Bool
    /// True when the habit's reminder hours can't remind, notifications aren't allowed
    let isNotificationReminderPaused: (Habit) -> Bool
    var onItemAction: (Habit) -> Void

    var body: some View {
        if self.isEmptyStateVisible {
            HabitsEmptyView()
        } else {
            self.habitsList
        }
    }

    private var habitsList: some View {
        List(self.list) { habit in
            let dividerColor = self.list.count == 1 ?
                Color.black.opacity(0.0) : nil

            ListItem(
                name: habit.name,
                type: .noStatusListItem,
                location: habit.location,
                locationDistance: habit.location.flatMap { self.distance($0) },
                isLocationReminderPaused: self.isLocationReminderPaused(habit),
                isNotificationReminderPaused: self.isNotificationReminderPaused(habit),
                hasLocationReminder: habit.hasLocationReminder,
                status: .constant(false),
                statusAction: {},
                itemAction: { onItemAction(habit) }
            )
            .listItemRowInsets()
            .listRowSeparatorTint(dividerColor)
            // No divider above the first habit
            .listRowSeparator(habit.id == self.list.first?.id ? .hidden : .automatic, edges: .top)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
