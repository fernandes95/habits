//
//  DatePickerSheetContent.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/01/2024.
//

import SwiftUI

struct DatePickerSheetContent: View {
    @Binding var datePickerDate: Date
    var todayAction: () -> Void
    var doneAction: () -> Void
    var todayButtonDisabled: Bool
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Button("Today", role: .none, action: todayAction)
                .disabled(todayButtonDisabled)
                Spacer()
                    .buttonStyle(.borderless)
                Button("Done", role: .none, action: doneAction)
                .buttonStyle(.borderless)
            }
            .padding([.top, .horizontal])
            
            DatePicker(
                "",
                selection: $datePickerDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
        }
        .modifier(RelativeHeightSheetContent())
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    DatePickerSheetContent(datePickerDate: .constant(Date.now), todayAction: { }, doneAction: { }, todayButtonDisabled: false)
}
