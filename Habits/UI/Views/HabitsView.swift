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
    
    @State private var date = Date.now
    @State private var isPresentingNewHabit = false
    @State private var didLoadData = false
    
    var body: some View {
        VStack {
            HeaderView(
                date: $date,
                changeDateAction: { 
                    Task {
                        do {
                            try await state.loadHabits(date: date)
                        } catch { }
                    }
                }
            )
            .padding([.top, .horizontal])
            
            ContentView(
                list: $state.items,
                onItemStatusAction: { habit in
                    Task {
                        do {
                            try await state.updateHabit(habit: habit)
                        } catch { }
                    }
                },
                onItemAction: { habit in
                    router.push(HabitDetailView(habit: habit))
                }, 
                onDeleteAction: { habit in
                    Task {
                        do {
                            try await state.updateHabit(habit: habit)
                        } catch { }
                    }
                }
            )
        }
        .task {
            if !didLoadData {
                Task {
                    do {
                        try await state.loadHabits(date: date)
                    } catch { }
                }
                didLoadData = true
            }
        }
        .navigationTitle("habits_title")
        .toolbar {
            Button(action: { isPresentingNewHabit = true }) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("habits_accessibility_new_habit")
        }
        .sheet(isPresented: $isPresentingNewHabit) {
            NewHabitView(
                isPresentingNewHabit: $isPresentingNewHabit,
                startDate: date
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
            Button(action: { changeDate(dateOption: DateOption.Previous) }) {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("habits_accessibility_previous_day")
            Spacer()
            HStack {
                if date.formatDate() == todayDate {
                    Text("general_today")
                }
                else {
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
            Button(action: { changeDate(dateOption: DateOption.Next) }) {
                Image(systemName: "chevron.right")
            }
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
        case Previous = -1
        case Next = 1
    }
}

private struct ContentView: View {
    @Binding var list: [Habit]
    var onItemStatusAction: (Habit) -> Void
    var onItemAction: (Habit) -> Void
    var onDeleteAction: (Habit) -> Void
    
    var body: some View {
        List {
            ForEach($list) { $habit in
                let isLast = habit == list.last
              
                ListItem(
                    name: habit.name,
                    status: $habit.isChecked,
                    statusAction: { onItemStatusAction(habit) },
                    itemAction: { onItemAction(habit) }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        var habitDeleted = habit
                        habitDeleted.isDeleted = true
                        
                        onDeleteAction(habitDeleted)
                    } label: {
                        Label("habit_detail_delete", systemImage: "trash")
                    }
                }
                .listRowSeparator(.hidden, edges: isLast ? .bottom : .top)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    HabitsView()
        .environmentObject(MainState())
}
