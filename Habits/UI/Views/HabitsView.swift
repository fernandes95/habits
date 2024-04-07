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

    @State private var isPresentingNewHabit = false
    @State private var didLoadData = false
    @State private var viewType: ViewType = .list

    var body: some View {
        VStack {
            if viewType == .list {
                HeaderView(
                    date: $state.selectedDate,
                    changeDateAction: {
                        Task {
                            do {
                                try await state.loadHabits(date: state.selectedDate)
                            } catch { }
                        }
                    }
                )
                .padding([.top, .horizontal])
            }

            if viewType == .list {
                ContentView(
                    list: $state.habits,
                    onItemStatusAction: { habit in
                        Task {
                            do {
                                try await state.updateHabit(habit: habit)
                            } catch { }
                        }
                    },
                    onItemAction: { habit in
                        router.push(HabitDetailView(habit: habit))
                    }
                )
            } else {
                CalendarView()
            }
        }
        .task {
            if !didLoadData {
                Task {
                    do {
                        try await state.loadHabits(date: state.selectedDate)
                    } catch { }
                }
                didLoadData = true
            }
        }
        .navigationTitle("habits_title")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { viewType = viewType == .calendar ? .list : .calendar },
                       label: {
                    let systemName = getViewTypeSystemName(viewType: viewType)
                    Image(systemName: systemName)
                })
                .accessibilityLabel("habits_accessibility_change_view")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isPresentingNewHabit = true }, label: {
                    Image(systemName: "plus")
                })
                .accessibilityLabel("habits_accessibility_new_habit")
            }
        }
        .sheet(isPresented: $isPresentingNewHabit) {
            NewHabitView(
                isPresentingNewHabit: $isPresentingNewHabit,
                startDate: state.selectedDate
            )
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
    var onItemStatusAction: (Habit) -> Void
    var onItemAction: (Habit) -> Void

    var body: some View {
        List {
            ForEach($list) { $habit in
                let dividerColor = $list.count == 1 ?
                    Color.black.opacity(0.0) : nil

                ListItem(
                    name: habit.name,
                    status: $habit.isChecked,
                    statusAction: {
                        var habitChecked = habit
                        habitChecked.isChecked = !habitChecked.isChecked
                        onItemStatusAction(habitChecked)
                    },
                    itemAction: { onItemAction(habit) }
                )
                .listRowSeparatorTint(dividerColor)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    HabitsView()
        .environmentObject(MainState())
}
