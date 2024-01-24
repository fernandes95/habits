//
//  ContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

struct HabitsView: View {
    @Binding var habits: [Habit]
    @State private var showDatePicker = false
    @State private var datePickerDate = Date.now
    @State private var date = Date.now
    private let todayDate = Date().formatDate()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: { changeDate(day: -1) }) {
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
                    Button(action: { changeDate(day: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("Next Day")
                }
                .padding([.top, .horizontal])
                
                List($habits) { $habit in
                    ListItem(name: habit.name, status: habit.status)
                        
                }
                .listStyle(.plain)
                
                .navigationTitle("Habits")
                .toolbar {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Habit")
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
    HabitsView(habits: .constant(Habit.sampleData))
}
