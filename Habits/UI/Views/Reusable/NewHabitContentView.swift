//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI

struct NewHabitContentView: View {
    @Binding var name: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var frequency: Habit.Frequency
    @Binding var category: Habit.Category
    @Binding var schedule: [Habit.Hour]
    @Binding var isEdit: Bool
    let isNew: Bool
    var startDateIn: Date = Date.now
    var successRate: String? = nil
    
    @State private var hoursDate: Date = Date.now
    
    var body: some View {
        Form {
            Section(header: Text("habit_new_section_habit_info")) {
                TextField("habit_name", text: $name)
                    .disabled(!isEdit)
                
                Picker("habit_category", selection: $category) {
                    ForEach(Habit.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .disabled(!isEdit)
                
                DatePicker("habit_start_date", selection: $startDate,
                           in: startDateIn...,
                           displayedComponents: .date
                )
                .disabled(!isNew)
                
                DatePicker("habit_end_date", selection: $endDate,
                           in: startDate...,
                           displayedComponents: .date)
                .disabled(!isEdit)
            }
            
            Section(header: Text("habit_new_section_habit_frequency")) {
                Picker("habit_frequency", selection: $frequency) {
                    ForEach(Habit.Frequency.allCases) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .disabled(!isEdit)
            }
            
            if schedule.count > 0 || schedule.count == 0 && isEdit  {
                Section {
                    ForEach($schedule) { $hour in
                        if let index = schedule.firstIndex(of: hour){
                            let datePicker = DatePicker("Hour #\(index + 1)",
                                                        selection: $hour.date,
                                                        displayedComponents: .hourAndMinute
                            )
                            
                            if !isEdit {
                                datePicker
                            } else {
                                datePicker
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            schedule.remove(at: index)
                                        } label: {
                                            Label("habit_schedule_delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .disabled(!isEdit)
                } header: {
                    HStack {
                        Text("habit_new_section_habit_schedule")
                        Spacer()
                        if isEdit {
                            Button(action: {
                                schedule.append(Habit.Hour(date: Date.now))
                            }) {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("habits_accessibility_new_schedule_hour")
                        }
                    }
                }
            }

            if !isNew && successRate != nil {
                Text(successRate!)
                    .disabled(true)
            }
        }
    }
}

#Preview {
    NewHabitContentView(
        name: .constant("cenas"),
        startDate: .constant(Date.now),
        endDate: .constant(Date.now),
        frequency: .constant(.daily),
        category: .constant(.new),
        schedule: .constant([]),
        isEdit: .constant(true),
        isNew: true,
        successRate: "70%"
    )
}
