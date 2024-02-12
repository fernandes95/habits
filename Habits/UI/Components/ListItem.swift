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
    
    var body: some View {
        Toggle(isOn: $status) {
            Text(self.name).strikethrough(status)
        }
        .toggleStyle(checkBoxStyle())
        .padding(.vertical)
    }
    
}

struct checkBoxStyle: ToggleStyle {
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
        ListItem(name: "Test", status: .constant(false))
        ListItem(name: "Test 1", status: .constant(true))
    }
}
