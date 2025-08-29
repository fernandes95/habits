//
//  NewHabitLocationView.swift
//  Habits
//
//  Created by Tiago Fernandes on 17/09/2024.
//

import SwiftUI
import CoreLocation
import MapKit

struct NewHabitLocationView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @Environment(\.scenePhase)
    private var scenePhase: ScenePhase

    @Binding
    var habit: Habit

    @State private var searchQuery: String = ""
    @State private var selectedLocation: MKCoordinateRegion?
    @State private var hasLocationAuth: Bool = false
    @State private var hasNotificationAuth: Bool = false

    private let locationSearchService: LocationSearchService = LocationSearchService(completer: .init())

    var body: some View {
        VStack {
            Text("new_habit_location_title")
                .font(.largeTitle)
                .fontWeight(.bold)

            ZStack {
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("habit_location_search", text: $searchQuery)
                            .onChange(of: self.searchQuery) { query in
                                locationSearchService.update(queryFragment: query)
                            }
                            .submitLabel(.done)
                        if searchQuery != "" {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.medium)
                                .foregroundColor(Color(.systemGray3))
                                .padding(3)
                                .onTapGesture {
                                    withAnimation {
                                        self.searchQuery = ""
                                      }
                                }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.vertical, 10)

                    ZStack {
                        MapView(
                            position: self.$selectedLocation,
                            selectedLocation: self.$habit.location,
                            canEdit: .constant(true)
                        )

                        if !self.searchQuery.isEmpty && !locationSearchService.completions.isEmpty {
                            List {
                                ForEach(locationSearchService.completions) { completion in
                                    Button(
                                        action: { selectCompletionLocation(completion) },
                                        label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(completion.title)
                                                    .font(.headline)
                                                    .fontDesign(.rounded)
                                                Text(completion.subTitle)
                                            }
                                        }
                                    )
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
                if !self.hasLocationAuth || !self.hasNotificationAuth {
                    VStack(alignment: .center) {
                        Text("new_habit_location_setttings_info")

                        if !self.hasLocationAuth {
                            Text("new_habit_location_settings_location")
                        }

                        if self.hasLocationAuth && !self.hasNotificationAuth {
                            Text("new_habit_location_settings_notification")
                        }
                        Spacer()
                        Button(action: {
                                Task {
                                    await self.state.openSettings()
                                }
                            }, label: {
                                Text("Open Settings")
                                    .padding()
                                    .foregroundStyle(Color.white)
                                    .background(Color.blue)
                                    .cornerRadius(40)
                            }
                        )
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

            if self.hasLocationAuth && !self.hasNotificationAuth {
                try await self.state.getNotificationsAuthorization()
                self.hasNotificationAuth = try await self.state.getNotificationsAuthorizationStatus()
            }
        }
    }

    private func selectCompletionLocation(_ completion: LocationSearchCompletion) {
        Task {
            if let singleLocation = try? await locationSearchService
                .search(with: "\(completion.title) \(completion.subTitle)")
                .first {
                    selectedLocation = MKCoordinateRegion(
                        center: singleLocation.location,
                        latitudinalMeters: 150,
                        longitudinalMeters: 150
                    )
                    self.searchQuery = ""
                }
        }
    }
}

#Preview {
    NewHabitLocationView(habit: .constant(Habit.empty))
}
