//
//  LocationAlwaysSheetContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/10/2026.
//

import SwiftUI

/// Explains why location reminders need the `Always` location permission
/// and how to allow it in Settings.
struct LocationAlwaysSheetContentView: View {
    var openSettingsAction: () -> Void
    var withoutReminderTitle: LocalizedStringKey
    var withoutReminderAction: () -> Void
    var closeAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "location.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 72, height: 72)
                    .background(.tint.opacity(0.15), in: .circle)

                Text("habit_location_always_title")
                    .font(.title2.bold())

                Text("habit_location_always_message")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 0) {
                self.step(1, "habit_location_always_step_open_settings")
                Divider().padding(.leading, 52)
                self.step(2, "habit_location_always_step_tap_location")
                Divider().padding(.leading, 52)
                self.step(3, "habit_location_always_step_choose_always")
            }
            .background(.fill.tertiary, in: .rect(cornerRadius: 26))

            VStack(spacing: 8) {
                Button(action: self.openSettingsAction) {
                    Text("general_open_settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .prominentCapsuleButtonStyle()
                .accessibilityIdentifier("location_always_open_settings")

                Button(self.withoutReminderTitle, action: self.withoutReminderAction)
                    .buttonStyle(.borderless)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("location_always_without_reminder")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .padding(.bottom, 16)
        .overlay(alignment: .topTrailing) {
            Button(action: self.closeAction) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .glassCapsule()
            .padding(16)
            .accessibilityLabel("general_dismiss")
        }
        // Measures the full height of the text, otherwise the first small detent squeezes and cuts it
        .fixedSize(horizontal: false, vertical: true)
        .modifier(RelativeHeightSheetContent())
        .presentationDragIndicator(.visible)
    }

    private func step(_ number: Int, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(.fill.secondary, in: .circle)

            Text(title)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
    }
}

private extension View {
    /// Liquid Glass prominent capsule on iOS 26, bordered prominent on older versions
    @ViewBuilder
    func prominentCapsuleButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LocationAlwaysSheetContentView(
                openSettingsAction: { },
                withoutReminderTitle: "new_habit_add_without_reminder",
                withoutReminderAction: { },
                closeAction: { }
            )
        }
}
