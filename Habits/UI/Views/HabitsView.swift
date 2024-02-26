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
                changeDateAction: { state.loadHabits(date: date) }
            )
            .padding([.top, .horizontal])
            
            ContentView(
                list: $state.items,
                onItemStatusAction: { id in
//                    store.changeHabitStatus(habitId: id)
                },
                onItemAction: { habit in
                    router.push(HabitDetailView(habit: habit))
                }, 
                onDeleteAction: { id in
//                    store.removeHabit(id)
                }
            )
        }
        .task {
            if !didLoadData {
                state.loadHabits(date: date)
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
    @Binding var list: [MainState.Item]
    var onItemStatusAction: (UUID) -> Void
    var onItemAction: (MainState.Item) -> Void
    var onDeleteAction: (UUID) -> Void
    
    var body: some View {
        List {
            ForEach($list) { $habit in
                let isLast = habit == list.last
              
                ListItem(
                    name: habit.name,
                    status: $habit.isChecked,
                    statusAction: { onItemStatusAction(habit.id) },
                    itemAction: { onItemAction(habit) }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDeleteAction(habit.id)
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
