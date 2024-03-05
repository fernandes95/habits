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
    @Binding var frequency: String
    @Binding var category: Habit.Category
    @Binding var isEdit: Bool
    let isNew: Bool
    var startDateIn: Date = Date.now
    
    var body: some View {
        Form {
            Section(header: Text("habit_new_section_habit_info")) {
                TextField("habit_name", text: $name)
                    .disabled(!isEdit)
                
                Picker("habit_category", selection: $category) {
                    ForEach(Habit.Category.allCases) { category in
                        Text(getCategoryName(category)).tag(category)
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
                TextField("", text: $frequency)
                    .disabled(true)
            }
            
            Section(header: Text("habit_new_section_habit_frequency")) {
                
            }
        }
    }
}

#Preview {
    NewHabitContentView(
        name: .constant("cenas"),
        startDate: .constant(Date.now),
        endDate: .constant(Date.now),
        frequency: .constant("Monthly"),
        category: .constant(.newHabit),
        isEdit: .constant(true),
        isNew: true
    )
}
