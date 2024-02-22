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
    private var store: StoreHabits
    
    @State private var showDatePicker = false
    @State private var datePickerDate = Date.now
    @State private var date = Date.now
    private let todayDate = Date().formatDate()
    @State var isPresentingNewHabit = false
    @State var didLoadData = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
            VStack {
                HStack {
                    Button(action: {
                        changeDate(day: -1) // TODO: create enum previous and next for day param
                        store.filterListByDate(date: date)
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Previous Day")
                    Spacer()
                    HStack {
                        if date.formatDate() == todayDate {
                            Text("Today")
                        }
                        else {
                            Text(date, style: .date)
                        }
                    }
                    .onTapGesture {
                        showDatePicker.toggle()
                    }
                    .sheet(isPresented: $showDatePicker) {
                        DatePickerSheetContent(
                            datePickerDate: $datePickerDate,
                            todayAction: {
                                showDatePicker.toggle()
                                date = Date()
                                datePickerDate = date
                                store.filterListByDate(date: date)
                            },
                            doneAction: {
                                showDatePicker.toggle()
                                date = datePickerDate
                                store.filterListByDate(date: date)
                            },
                            todayButtonDisabled: date.formatDate() == todayDate
                        )
                    }
                    Spacer()
                    Button(action: {
                        changeDate(day: 1)
                        store.filterListByDate(date: date)
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("Next Day")
                }
                .padding([.top, .horizontal])
                
                List {
                    ForEach($store.filteredHabits) { $habit in
                        let isLast = habit == store.filteredHabits.last
                        
                        ZStack(alignment: .leading) {
                            ListItem(
                                name: habit.name,
                                status: $habit.status
                            )
                            .onTapGesture {
                                //TODO: FIX LAYOUT TO SEPARATE CHECK ACTION FROM DETAIL ACTION
//                                changeStatusAction(habit.id)
                                router.push(
                                    HabitDetailView(habit: $habit)
                                )
                            }
                            .listRowSeparator(.hidden, edges: isLast ? .bottom : .top)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .task {
                if !didLoadData {
                    do {
                        try await store.load()
                        didLoadData = true
                    } catch {
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                Button(action: { isPresentingNewHabit.toggle() }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Habit")
            }
        .sheet(isPresented: $isPresentingNewHabit) {
            NewHabitView(
                isPresentingNewHabit: $isPresentingNewHabit,
                habits: $store.habits,
                startDate: date,
                updateList: { store.filterListByDate(date: date) }
            )
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive {
                Task {
                    do {
                        try await store.save()
                    } catch {
                    }
                }
            }
        }
    }
    
    private func changeDate(day: Int) {
        var dateComponent = DateComponents()
        dateComponent.day = day
        if let newDate = Calendar.current.date(byAdding: dateComponent, to: date) {
            date = newDate
            datePickerDate = date
        }
    }
}

extension Date {
    func formatDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        return dateFormatter.string(from: self)
    }
}

#Preview {
    HabitsView()
}
