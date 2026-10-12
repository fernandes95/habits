//
//  ContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State private var didLoadData = false

    var body: some View {
        VStack {
            HeaderView(
                date: self.$state.selectedDate,
                progress: self.state.dayProgress,
                changeDateAction: self.loadSelectedDate,
                settingsAction: { self.router.push(SettingsView()) }
            )
            .padding(.horizontal)
            .padding(.bottom, 12)

            ZStack(alignment: .bottomTrailing) {
                DaySwipeContainer(onSwipe: changeDay) {
                    ContentView(
                        list: self.$state.habits,
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

                Button {
                    self.router.push(NewHabitQuoteView())
                } label: {
                    Image(systemName: "plus")
                        .font(.title.weight(.medium))
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                        .shadow(radius: 4, x: 0, y: 4)

                }
                .accessibilityLabel("habits_accessibility_new_habit")
                .padding(20)
            }
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if !didLoadData {
                self.reloadAll()
                didLoadData = true
            }
        }
        .navigationTitle("habits_title")
        .toolbar(.hidden, for: .navigationBar)
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
                    status: $habit.isChecked,
                    statusAction: {
                        var habit = habit
                        habit.isChecked = !habit.isChecked
                        onItemStatusAction(habit)
                    },
                    itemAction: { onItemAction(habit) }
                )
                .listRowSeparatorTint(dividerColor)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // Keeps the empty area swipeable when there are no habits
        .contentShape(Rectangle())
    }
}
