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
    }
    
}
