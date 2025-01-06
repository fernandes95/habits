//
//  NewHabitLocationView.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/09/2024.
//

import SwiftUI

struct NewHabitLocationView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState
    
    @Environment(\.scenePhase)
    private var scenePhase: ScenePhase

    @Binding
    var habit: Habit

    @State private var hasLocationAuth: Bool = false
    @State private var hasNotificationAuth: Bool = false

    var body: some View {
        VStack {
            Text("new_habit_location_title")
                .font(.largeTitle)
                .fontWeight(.bold)

            ZStack {
                Form {
                    Section(header: Text("new_habit_location_section_title")) {
                        VStack {
                            Text("new_habit_location_info")

                            MapView(location: self.$habit.location, canEdit: .constant(true))
                                .frame(height: 250)
                                .cornerRadius(10)
                        }
                    }
                }
                if !self.hasLocationAuth || !self.hasNotificationAuth {
                    VStack(alignment: .center) {
                        Text("This feature will send a notification based on the selected location.\n"
                             + "We do not store any data regarding your location besides the selected location.")
                        let txt = """
                        Follow the following steps to enable location permissions:

                        1. Open Settings
                        2. Select ALWAYS allow location
                        3. Select Precise Location toggle if not already selected


                        Follow the following steps to enable notification permissions:

                        1. Open Settings
                        2. Select notification
                        3. Select Allow notifications toggle
                        """
                        Text(txt)
                        Spacer()
                        Button(action: {
                            Task {
                                await self.state.openSettings()
                            }
                        }) {
                            Text("Open Settings")
                                .padding()
                                .foregroundStyle(Color.white)
                                .background(Color.blue)
                                .cornerRadius(40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    Spacer()
                }
            }
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("general_next") {
                    self.router.push(NewHabitResumeView(habit: self.$habit))
                }
            }
        }
        .onAppear {
            updatePerms()
        }
        .onChange(of: self.scenePhase) { (newValue: ScenePhase) in
            switch newValue {
            case .active:
                updatePerms()
            default:
                break
            }
        }
        
    }
    
    func updatePerms() {
        Task {
            self.hasLocationAuth = self.state.getLocationAuthorizationStatus()
            self.hasNotificationAuth = try await self.state.getNotificationsAuthorizationStatus()
        }
    }
}

#Preview {
    NewHabitLocationView(habit: .constant(Habit.empty))
}
