import Foundation
import CoreLocation

final class GeocodingService {
    private let geocoder = CLGeocoder()

    func reverseGeocode(_ location: CLLocation) async throws -> ResolvedPlacemark {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw GeocodingError.cityNotFound
        }

        let city = placemark.locality
            ?? placemark.subAdministrativeArea
            ?? placemark.administrativeArea
        let country = placemark.country
        let district = placemark.subLocality
            ?? placemark.subAdministrativeArea
            ?? placemark.name

        guard let city, let country, !city.isEmpty, !country.isEmpty else {
            throw GeocodingError.cityNotFound
        }

        let sanitizedDistrict = district?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ResolvedPlacemark(
            countryName: country,
            cityName: city,
            districtName: sanitizedDistrict?.isEmpty == true ? nil : sanitizedDistrict
        )
    }
}

enum GeocodingError: LocalizedError {
    case cityNotFound

    var errorDescription: String? {
        switch self {
        case .cityNotFound:
            return "Could not determine your city from the current location."
        }
    }
}
