//
//  LocationCardView.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/10/2026.
//

import SwiftUI
import MapKit
import Contacts

/// Location row with the place name, its address and a small map with the pin.
/// When `place` is nil the name and address are looked up from the coordinate,
/// so it also works for saved habits that only have coordinates.
struct LocationCardView: View {
    let location: Habit.Location
    var place: LocationPlaceDetails?
    /// Makes the name, address and map tappable, usually to open the location picker
    var onTap: (() -> Void)?
    /// Shows the remove button when set
    var onClear: (() -> Void)?

    @State private var resolvedPlace: LocationPlaceDetails?
    @State private var isResolving: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let onTap = self.onTap {
                Button(action: onTap) {
                    self.content
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("location_card")
            } else {
                self.content
            }

            if let onClear = self.onClear {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("habit_location_accessibility_remove")
                .accessibilityIdentifier("location_card_clear")
            }
        }
        .padding(16)
        .background(.fill.tertiary, in: .rect(cornerRadius: 26))
        .task(id: self.coordinateKey) {
            await self.resolvePlace()
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let name = self.displayedPlace?.name {
                    Text(verbatim: name)
                        .font(.title3)
                        .foregroundStyle(.primary)
                } else {
                    Text("habit_location_pinned")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }

                if let address = self.displayedPlace?.address {
                    Text(verbatim: address)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .redacted(reason: self.isResolving && self.displayedPlace == nil ? .placeholder : [])

            LocationThumbnail(coordinate: self.location.locationCoordinate)
        }
        .contentShape(.rect)
    }

    private var displayedPlace: LocationPlaceDetails? {
        self.place ?? self.resolvedPlace
    }

    private var coordinateKey: String {
        "\(self.location.latitude),\(self.location.longitude)"
    }

    /// Reverse geocodes the coordinate when no name or address was given
    private func resolvePlace() async {
        self.resolvedPlace = nil
        guard self.place == nil else { return }

        self.isResolving = true
        defer { self.isResolving = false }

        let location = CLLocation(latitude: self.location.latitude, longitude: self.location.longitude)
        guard let placemark: CLPlacemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return
        }

        let address: String? = placemark.postalAddress.map { (postalAddress: CNPostalAddress) in
            CNPostalAddressFormatter
                .string(from: postalAddress, style: .mailingAddress)
                .replacingOccurrences(of: "\n", with: ", ")
        }

        guard let name = placemark.name ?? address else { return }

        self.resolvedPlace = LocationPlaceDetails(name: name, address: address)
    }
}

/// Small non interactive map centered on the pin
private struct LocationThumbnail: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: self.coordinate,
                    latitudinalMeters: .regionRadius * 4,
                    longitudinalMeters: .regionRadius * 4
                )
            ),
            interactionModes: []
        ) {
            Annotation("", coordinate: self.coordinate) {
                Image(systemName: "mappin")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.red, in: .circle)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            }
            .annotationTitles(.hidden)
        }
        .mapControlVisibility(.hidden)
        .allowsHitTesting(false)
        .frame(width: 110, height: 110)
        .clipShape(.rect(cornerRadius: 16))
        // initialPosition is only read once, a new pin needs a new map
        .id("\(self.coordinate.latitude),\(self.coordinate.longitude)")
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 16) {
        LocationCardView(
            location: Habit.Location(
                latitude: 38.7695,
                longitude: -9.2245,
                region: .around(CLLocationCoordinate2D(latitude: 38.7695, longitude: -9.2245))
            ),
            place: LocationPlaceDetails(
                name: "Centro Comercial Continente Amadora",
                address: "Estrada Nacional 249/1, 2724-510 Amadora, Portugal"
            ),
            onTap: {},
            onClear: {}
        )

        LocationCardView(
            location: Habit.Location(
                latitude: 38.7369,
                longitude: -9.1426,
                region: .around(CLLocationCoordinate2D(latitude: 38.7369, longitude: -9.1426))
            )
        )
    }
    .padding()
}
