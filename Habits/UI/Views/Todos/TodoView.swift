//
//  TodoView.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

/// To-dos tab, shows a coming soon message until to-dos are available
struct TodoView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 104, height: 104)
                .background(.tint.opacity(0.15), in: .rect(cornerRadius: 26))
                .padding(.bottom, 16)

            Text("todos_coming_soon_badge")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.fill.tertiary, in: .capsule)
                .overlay(Capsule().stroke(.separator, lineWidth: 1))

            Text("todos_coming_soon_title")
                .font(.largeTitle.bold())

            Text("todos_coming_soon_message")
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    TodoView()
}
