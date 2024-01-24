//
//  ListItem.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/01/2024.
//

import SwiftUI

struct ListItem: View {
    let name: String
    let status: Bool
    
    var body: some View {
        Toggle(isOn: .constant(self.status)) {
            Text(self.name)
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
        }.onTapGesture { configuration.isOn.toggle() }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ListItem(name: "Test", status: false)
}
