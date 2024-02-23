//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI

struct NewHabitContentView: View {
    @Binding var habitName: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isEdit: Bool
    let isNew: Bool
    
    var body: some View {
        Form {
            Section(header: Text("habit_new_section_habit_info")) {
                TextField("habit_name", text: $habitName)
                    .disabled(!isEdit)
                
                DatePicker("habit_start_date", selection: $startDate,
                           in: Date()...,
                           displayedComponents: .date
                )
                .disabled(!isNew)
                
                DatePicker("habit_end_date", selection: $endDate,
                           in: startDate...,
                           displayedComponents: .date)
                .disabled(!isEdit)
            }
            
//                if startDate.formatDate() != endDate.formatDate() {
//                    Picker("habit_frequency", selection: $frequency, content: {
//                        ForEach(HabitFrequency.allCases) { frequency in
//                            Text(frequency.rawValue.capitalized).tag(frequency)
//                        }
//                    }).pickerStyle(.menu)
//                }
        }
    }
}

#Preview {
    NewHabitContentView(
        habitName: .constant("cenas"),
        startDate: .constant(Date.now),
        endDate: .constant(Date.now),
        isEdit: .constant(true),
        isNew: true)
}
