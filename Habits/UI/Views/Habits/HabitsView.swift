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
    private var state: MainState

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
                        changeDateAction: self.loadSelectedDate
                    )
                case .all:
                    AllHabitsHeaderView()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            ZStack(alignment: .bottomTrailing) {
                switch self.viewMode {
                case .today:
                    self.dayContent
                case .week:
                    DaySwipeContainer(onSwipe: changeDay) {
                        self.dayContent
                    }
                case .all:
                    AllHabitsContentView(
                        list: self.state.allHabits,
                        distance: self.state.distance(to:),
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
        ContentView(
            list: self.$state.habits,
            selectedDate: self.state.selectedDate,
            calendar: self.state.calendar,
            distance: self.state.distance(to:),
            onItemStatusAction: { habit in
                Task {
                    do {
                        try await self.state.updateHabit(habit: habit)
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

    /// Moves the selected date by `days` (negative goes back) and waits until it's loaded
    private func changeDay(by days: Int) async {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: state.selectedDate) else { return }
        do {
            try await state.selectDate(newDate, animated: false)
        } catch let error { print(error.localizedDescription) }
    }
}

extension Color {
    static let dayProgress = Color(red: 0.39, green: 0.77, blue: 0.39)
    static let dayTrack = Color(.systemGray5)
}

private struct ContentView: View {
    @Binding var list: [Habit]
    let selectedDate: Date
    /// Calendar with the configured first day of the week
    let calendar: Calendar
    /// Distance from the user to a habit location, nil while the user location is unknown
    let distance: (Habit.Location) -> CLLocationDistance?
    var onItemStatusAction: (Habit) -> Void
    var onItemAction: (Habit) -> Void

    var body: some View {
        List {
            ForEach($list) { $habit in
                let totalSteps = habit.frequency == .minTimes ? habit.frequencyType.minimumTimes : 0
                let dividerColor = $list.count == 1 ?
                    Color.black.opacity(0.0) : nil

                ListItem(
                    name: habit.name,
                    completedSteps: habit.completedCount,
                    totalSteps: totalSteps,
                    label: self.minDaysLabel(for: habit),
                    location: habit.location,
                    locationDistance: habit.location.flatMap { self.distance($0) },
                    status: $habit.isChecked,
                    statusAction: {
                        var habit = habit
                        habit.isChecked = !habit.isChecked
                        onItemStatusAction(habit)
                    },
                    itemAction: { onItemAction(habit) }
                )
                .listRowSeparatorTint(dividerColor)
                // No divider above the first habit
                .listRowSeparator(habit.id == list.first?.id ? .hidden : .automatic, edges: .top)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // Keeps the empty area swipeable when there are no habits
        .contentShape(Rectangle())
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
    /// Distance from the user to a habit location, nil while the user location is unknown
    let distance: (Habit.Location) -> CLLocationDistance?
    var onItemAction: (Habit) -> Void

    var body: some View {
        List(self.list) { habit in
            let dividerColor = self.list.count == 1 ?
                Color.black.opacity(0.0) : nil

            ListItem(
                name: habit.name,
                type: .noStatusListItem,
                location: habit.location,
                locationDistance: habit.location.flatMap { self.distance($0) },
                status: .constant(false),
                statusAction: {},
                itemAction: { onItemAction(habit) }
            )
            .listRowSeparatorTint(dividerColor)
            // No divider above the first habit
            .listRowSeparator(habit.id == self.list.first?.id ? .hidden : .automatic, edges: .top)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
