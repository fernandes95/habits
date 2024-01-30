//
//  ContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

struct HabitsView: View {
    @Binding var habits: [Habit]
    @Binding var habitsFiltered: [Habit]
    @State private var showDatePicker = false
    @State private var datePickerDate = Date.now
    @State private var date = Date.now
    private let todayDate = Date().formatDate()
    @State var isPresentingNewHabit = false
    @Environment(\.scenePhase) private var scenePhase
    let changeDateAction: (Date)->Void
    let saveAction: ()->Void
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: {
                        changeDate(day: -1)
                        changeDateAction(date)
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
                            },
                            doneAction: {
                                showDatePicker.toggle()
                                date = datePickerDate
                            },
                            todayButtonDisabled: date.formatDate() == todayDate
                        )
                    }
                    Spacer()
                    Button(action: {
                        changeDate(day: 1)
                        changeDateAction(date)
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("Next Day")
                }
                .padding([.top, .horizontal])
                
                List {
                    ForEach($habitsFiltered) { $habit in
                        let isLast = habit == habitsFiltered.last
                        
                        ListItem(name: habit.name, status: $habit.status)
                            .onTapGesture {
                                habit.status = !habit.status
                            }
                            .listRowSeparator(.hidden, edges: isLast ? .bottom : .top)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Habits")
            .toolbar {
                Button(action: { isPresentingNewHabit.toggle() }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Habit")
            }
        }
        .sheet(isPresented: $isPresentingNewHabit) {
            NewHabitView(isPresentingNewHabit: $isPresentingNewHabit, habits: $habits, updateList: { changeDateAction(date) })
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive { saveAction() }
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
    HabitsView(habits: .constant(Habit.sampleData), habitsFiltered: .constant(Habit.sampleData), changeDateAction: {_ in }, saveAction: {})
}
