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
                    date: $state.selectedDate,
                    changeDateAction: {
                        Task {
                            do {
                                try await state.loadHabits(date: state.selectedDate)
                            } catch let error { print(error.localizedDescription) }
                        }
                    }
                )
                .padding([.top, .horizontal])
            ZStack(alignment: .bottomTrailing) {
                ContentView(
                    list: $state.habits,
                    date: $state.selectedDate,
                    onItemStatusAction: { habit in
                        Task {
                            do {
                                try await state.updateHabit(habit: habit)
                            } catch let error { print(error.localizedDescription) }
                        }
                    },
                    onItemAction: { habit in
                        router.push(HabitDetailView(habit: habit))
                    }
                )

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
        }
        .task {
            if !didLoadData {
                Task {
                    do {
                        try await state.loadHabits(date: state.selectedDate)
                    } catch let error { print(error.localizedDescription) }
                }
                didLoadData = true
            }
        }
        .navigationTitle("habits_title")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    self.router.push(SettingsView())
                }, label: {
                    Image(systemName: "gearshape.2.fill")
                })
                .accessibilityLabel("habits_accessibility_settings")
            }
        }
    }
}

private struct HeaderView: View {
    @Binding var date: Date
    var changeDateAction: () -> Void
    @State private var showDatePicker = false
    @State private var datePickerDate = Date.now
    private let todayDate = Date.now.formatDate()

    var body: some View {
        HStack {
            Button(action: { changeDate(dateOption: .previous) },
                label: {
                    Image(systemName: "chevron.left")
                }
            )
            .accessibilityLabel("habits_accessibility_previous_day")
            Spacer()
            HStack {
                if date.formatDate() == todayDate {
                    Text("general_today")
                } else {
                    Text(date, style: .date)
                }
            }
            .onTapGesture {
                showDatePicker = true
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheetContent(
                    datePickerDate: $datePickerDate,
                    todayAction: {
                        showDatePicker = false
                        date = Date()
                        datePickerDate = date
                        changeDateAction()
                    },
                    doneAction: {
                        showDatePicker = false
                        date = datePickerDate
                        changeDateAction()
                    },
                    todayButtonDisabled: date.formatDate() == todayDate
                )
            }
            Spacer()
            Button(action: { changeDate(dateOption: .next) }, label: {
                Image(systemName: "chevron.right")
            })
            .accessibilityLabel("habits_accessibility_next_day")
        }
    }

    private func changeDate(dateOption: DateOption) {
        var dateComponent = DateComponents()
        dateComponent.day = dateOption.rawValue
        if let newDate = Calendar.current.date(byAdding: dateComponent, to: date) {
            date = newDate
            datePickerDate = date
            changeDateAction()
        }
    }

    private enum DateOption: Int {
        case previous = -1
        case next = 1
    }
}

private struct ContentView: View {
    @Binding var list: [Habit]
    @Binding var date: Date
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
    }
}
