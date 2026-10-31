//
//  LocationPlaceDetails.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/10/2026.
//

import Foundation
import CoreLocation
import Contacts

/// Name and address shown for a habit location
struct LocationPlaceDetails: Equatable {
    var name: String
    var address: String?
}

extension LocationPlaceDetails {
    /// How long to wait for the geocoder, without a connection it may never answer
    private static let resolveTimeout: Duration = .seconds(5)

    /// Reverse geocodes a coordinate into a place name and address.
    /// Only used when a pin is dropped, the result is saved with the habit.
    ///
    /// - Returns: nil when nothing was found, the lookup failed or it took longer than `resolveTimeout`
    static func resolve(latitude: Double, longitude: Double) async -> LocationPlaceDetails? {
        await withTaskGroup(of: LocationPlaceDetails?.self) { group in
            group.addTask { await self.reverseGeocode(latitude: latitude, longitude: longitude) }
            group.addTask {
                try? await Task.sleep(for: self.resolveTimeout)
                return nil
            }
            // Whichever finishes first wins, the other one is cancelled
            let place = await group.next() ?? nil
            group.cancelAll()
            return place
        }
    }

    private static func reverseGeocode(latitude: Double, longitude: Double) async -> LocationPlaceDetails? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        let placemark: CLPlacemark? = await withTaskCancellationHandler {
            try? await geocoder.reverseGeocodeLocation(location).first
        } onCancel: {
            // Makes the pending lookup finish right away instead of waiting for the network
            geocoder.cancelGeocode()
        }
        guard let placemark else { return nil }

        let address: String? = placemark.postalAddress.map { (postalAddress: CNPostalAddress) in
            CNPostalAddressFormatter
                .string(from: postalAddress, style: .mailingAddress)
                .replacingOccurrences(of: "\n", with: ", ")
        }

        guard let name = placemark.name ?? address else { return nil }

        return LocationPlaceDetails(name: name, address: address)
    }
}
