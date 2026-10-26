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
    /// Places already looked up, keyed by coordinate, so lists don't geocode the same location again
    @MainActor
    private static var cache: [String: LocationPlaceDetails] = [:]

    /// Reverse geocodes a coordinate into a place name and address.
    /// Saved habits only keep coordinates, so this is how their place is shown.
    @MainActor
    static func resolve(latitude: Double, longitude: Double) async -> LocationPlaceDetails? {
        let key = "\(latitude),\(longitude)"
        if let cached = self.cache[key] { return cached }

        let location = CLLocation(latitude: latitude, longitude: longitude)
        guard let placemark: CLPlacemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return nil
        }

        let address: String? = placemark.postalAddress.map { (postalAddress: CNPostalAddress) in
            CNPostalAddressFormatter
                .string(from: postalAddress, style: .mailingAddress)
                .replacingOccurrences(of: "\n", with: ", ")
        }

        guard let name = placemark.name ?? address else { return nil }

        let place = LocationPlaceDetails(name: name, address: address)
        self.cache[key] = place
        return place
    }
}
