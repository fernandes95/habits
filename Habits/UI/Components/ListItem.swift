//
//  ListItem.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/01/2024.
//

import SwiftUI

struct ListItem: View {
    let name: String
    @Binding var status: Bool
    let statusAction: () -> Void
    let itemAction: () -> Void
    var body: some View {
        HStack {
            Toggle(isOn: $status) {
                Text(self.name).strikethrough(status)
                    .lineLimit(1)
            }
            .padding([.vertical, .trailing])
            .toggleStyle(CheckBoxStyle())
            .onTapGesture { statusAction() }
            Spacer()
            Button(action: { itemAction() }, label: {
                Image(systemName: "chevron.right")
                    .padding(.leading)
            })
            .padding([.vertical, .leading])
        }
    }
}

struct CheckBoxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 20, height: 20)
            configuration.label
        }
    }
}

#Preview {
    VStack {
        ListItem(
            name: "LONG NAMEEEEEEEEEEEEEEEEEEEEE shfsjdfnsjdfbsljdfbs",
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
        ListItem(name: "Test 1", status: .constant(true), statusAction: {}, itemAction: {})
    }
}
