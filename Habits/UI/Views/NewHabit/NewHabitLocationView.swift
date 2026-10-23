//
//  NewHabitLocationPickerView.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/10/2026.
//

import SwiftUI
import MapKit

/// Bottom sheet with a full screen map to pick the location a habit reminds at.
/// Tapping the map or picking a search result drops the pin, the circle around it
/// is the region that gets monitored.
struct NewHabitLocationView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding
    var location: Habit.Location?

    @Binding
    var place: LocationPlaceDetails?

    @State private var draftLocation: Habit.Location?
    @State private var cameraRegion: MKCoordinateRegion?
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchedPlace: SearchedPlace?
    @State private var isSearching: Bool = false

    var body: some View {
        NavigationStack {
            MapView(
                position: self.$cameraRegion,
                selectedLocation: self.$draftLocation,
                canEdit: .constant(true),
                onCameraChange: { (region: MKCoordinateRegion) in
                    self.visibleRegion = region
                }
            )
            // Map keeps drawing under the inset, its logo and legal label stay above the search bar
            .safeAreaInset(edge: .bottom) {
                LocationSearchBar(title: self.draftPlace?.name) {
                    self.isSearching = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .navigationTitle("habit_location_picker_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        self.location = self.draftLocation
                        self.place = self.draftPlace
                        self.dismiss()
                    }
                    .disabled(self.draftLocation == nil)
                    .accessibilityIdentifier("location_picker_done")
                }
            }
            .sheet(isPresented: self.$isSearching) {
                LocationSearchView(
                    region: self.visibleRegion
                ) { (place: LocationPlaceDetails, coordinate: CLLocationCoordinate2D) in
                    self.select(place: place, coordinate: coordinate)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                self.draftLocation = self.location
                if let location = self.location {
                    self.cameraRegion = .around(location.locationCoordinate)
                    if let place = self.place {
                        self.searchedPlace = SearchedPlace(place: place, coordinate: location.locationCoordinate)
                    }
                }
            }
        }
    }

    /// Name  and address of the searched place while the pin is still on it,
    /// moving the pin by tapping the map drops the name
    private var draftPlace: LocationPlaceDetails? {
        guard let searchedPlace = self.searchedPlace,
              let draftLocation = self.draftLocation,
              draftLocation.latitude == searchedPlace.coordinate.latitude,
              draftLocation.longitude == searchedPlace.coordinate.longitude
        else {
            return nil
        }

        return searchedPlace.place
    }

    /// Goes to the searched place and drops the pin on it
    private func select(place: LocationPlaceDetails, coordinate: CLLocationCoordinate2D) {
        let region: MKCoordinateRegion = .around(coordinate)
        self.searchedPlace = SearchedPlace(place: place, coordinate: coordinate)

        withAnimation(.easeOut) {
            self.cameraRegion = region
            self.draftLocation = Habit.Location(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                region: region
            )
        }
    }

    private struct SearchedPlace {
        let place: LocationPlaceDetails
        let coordinate: CLLocationCoordinate2D
    }
}

/// Search field floating over the bottom of the map
private struct LocationSearchBar: View {
    let title: String?
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                Group {
                    if let title = self.title {
                        Text(title)
                            .foregroundStyle(.primary)
                    } else {
                        Text("habit_location_search")
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)

                Spacer(minLength: 0)
            }
            .font(.body)
            .padding(.horizontal, 18)
            .frame(height: 50)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassCapsule()
        .accessibilityIdentifier("location_search_bar")
    }
}

/// Address search, calls `onSelect` with the place found for the tapped completion
struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var locationSearchService: LocationSearchService = LocationSearchService(completer: .init())
    @State private var searchQuery: String = ""
    @State private var isResolving: Bool = false

    @FocusState private var searchFocused: Bool

    let region: MKCoordinateRegion?
    let onSelect: (LocationPlaceDetails, CLLocationCoordinate2D) -> Void

    var body: some View {
        NavigationStack {
            List {
                if !self.searchQuery.isEmpty {
                    ForEach(self.locationSearchService.completions) { (completion: LocationSearchCompletion) in
                        Button {
                            self.selectCompletionLocation(completion)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completion.title)
                                    .font(.headline)
                                    .fontDesign(.rounded)
                                Text(completion.subTitle)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .disabled(self.isResolving)
            .overlay {
                if self.isResolving {
                    ProgressView()
                }
            }
            .safeAreaInset(edge: .top) {
                self.searchField
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .navigationTitle("habit_location_search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        self.dismiss()
                    }
                }
            }
            .onAppear { self.searchFocused = true }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("habit_location_search", text: self.$searchQuery)
                .focused(self.$searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onChange(of: self.searchQuery) { _, query in
                    self.locationSearchService.update(queryFragment: query)
                }
                .accessibilityIdentifier("location_search_field")
            if !self.searchQuery.isEmpty {
                Button {
                    withAnimation {
                        self.searchQuery = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.medium)
                        .foregroundStyle(Color(.systemGray3))
                        .padding(3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .glassCapsule()
    }

    private func selectCompletionLocation(_ completion: LocationSearchCompletion) {
        Task {
            self.isResolving = true
            defer { self.isResolving = false }

            guard let result: LocationSearchResult = try? await self.locationSearchService
                .search(with: "\(completion.title) \(completion.subTitle)")
                .first
            else {
                return
            }

            let place = LocationPlaceDetails(
                name: completion.title,
                address: completion.subTitle.isEmpty ? nil : completion.subTitle
            )
            self.onSelect(place, result.location)
            self.dismiss()
        }
    }
}

extension MKCoordinateRegion {
    /// Region centered on `coordinate` that fits the monitored circle with some margin around it
    static func around(_ coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: .regionRadius * 6,
            longitudinalMeters: .regionRadius * 6
        )
    }
}

extension View {
    /// Liquid Glass capsule on iOS 26, material on older versions
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self
                .background(.regularMaterial, in: .capsule)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        }
    }
}

#Preview {
    NewHabitLocationView(location: .constant(nil), place: .constant(nil))
}
