import Foundation

final class PrayerAPIService {
    private let session: URLSession
    private let store: PrayerStore
    private let decoder = JSONDecoder()
    private let calendar = Calendar(identifier: .gregorian)
    private let baseURL = URL(string: "https://ezanvakti.emushaf.net")!

    private var countriesCache: [Country]?
    private var citiesCache: [String: [City]] = [:]
    private var districtsCache: [String: [District]] = [:]

    init(session: URLSession = .shared, store: PrayerStore) {
        self.session = session
        self.store = store
    }

    func fetchCountries() async throws -> [Country] {
        if let countriesCache {
            return countriesCache
        }

        let countries: [Country] = try await request(path: "/ulkeler")
        countriesCache = countries
        return countries
    }

    func fetchCities(countryID: String) async throws -> [City] {
        if let cached = citiesCache[countryID] {
            return cached
        }

        let cities: [City] = try await request(path: "/sehirler/\(countryID)")
        citiesCache[countryID] = cities
        return cities
    }

    func fetchDistricts(cityID: String) async throws -> [District] {
        if let cached = districtsCache[cityID] {
            return cached
        }

        let districts: [District] = try await request(path: "/ilceler/\(cityID)")
        districtsCache[cityID] = districts
        return districts
    }

    func fetchPrayerTimes(for selection: PrayerLocationSelection, forceRefresh: Bool = false) async throws -> PrayerTimes {
        if !forceRefresh, let cached = cachedPrayerTimes(for: selection, now: Date()) {
            return cached
        }

        let days: [DiyanetPrayerDay] = try await request(path: "/vakitler/\(selection.district.id)")
        let prayerTimes = try mapPrayerDays(days, selection: selection)
        store.savePrayerTimes(prayerTimes)
        return prayerTimes
    }

    func cachedPrayerTimes(for selection: PrayerLocationSelection, now: Date) -> PrayerTimes? {
        guard let cached = store.loadPrayerTimes() else { return nil }
        guard cached.districtID == selection.district.id else { return nil }
        guard cached.isSameDay(as: now) else { return nil }
        return cached
    }

    func resolveSelection(from placemark: ResolvedPlacemark) async throws -> PrayerLocationSelection {
        let countries = try await fetchCountries()
        guard let country = bestCountryMatch(for: placemark.countryName, in: countries) else {
            throw PrayerAPIServiceError.locationNotMatched
        }

        let cities = try await fetchCities(countryID: country.id)
        guard let city = bestCityMatch(for: placemark.cityName, in: cities) else {
            throw PrayerAPIServiceError.locationNotMatched
        }

        let districts = try await fetchDistricts(cityID: city.id)
        let district = bestDistrictMatch(for: placemark.districtName, in: districts) ?? districts.first

        guard let district else {
            throw PrayerAPIServiceError.locationNotMatched
        }

        return PrayerLocationSelection(country: country, city: city, district: district, isAutomatic: true)
    }

    private func bestCountryMatch(for name: String, in countries: [Country]) -> Country? {
        let key = name.prayerMatchingKey
        return countries.first(where: { $0.name.prayerMatchingKey == key || $0.englishName.prayerMatchingKey == key })
    }

    private func bestCityMatch(for name: String, in cities: [City]) -> City? {
        let key = name.prayerMatchingKey
        return cities.first(where: { $0.name.prayerMatchingKey == key || $0.englishName.prayerMatchingKey == key })
    }

    private func bestDistrictMatch(for name: String?, in districts: [District]) -> District? {
        guard let name, !name.isEmpty else { return nil }
        let key = name.prayerMatchingKey
        if let exact = districts.first(where: { $0.name.prayerMatchingKey == key || $0.englishName.prayerMatchingKey == key }) {
            return exact
        }

        return districts.first(where: {
            $0.name.prayerMatchingKey.contains(key) || key.contains($0.name.prayerMatchingKey)
                || $0.englishName.prayerMatchingKey.contains(key) || key.contains($0.englishName.prayerMatchingKey)
        })
    }

    private func mapPrayerDays(_ days: [DiyanetPrayerDay], selection: PrayerLocationSelection) throws -> PrayerTimes {
        guard !days.isEmpty else {
            throw PrayerAPIServiceError.invalidData
        }

        let todayEntry = try bestDayMatch(in: days)
        let timeZone = Self.timeZone(from: todayEntry.miladiTarihUzunIso8601) ?? .current
        let entries = try [
            PrayerTimeEntry(prayer: .fajr, time: parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.imsak, timeZone: timeZone)),
            PrayerTimeEntry(prayer: .sunrise, time: parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.gunes, timeZone: timeZone)),
            PrayerTimeEntry(prayer: .dhuhr, time: parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.ogle, timeZone: timeZone)),
            PrayerTimeEntry(prayer: .asr, time: parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.ikindi, timeZone: timeZone)),
            PrayerTimeEntry(prayer: .maghrib, time: parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.aksam, timeZone: timeZone)),
            PrayerTimeEntry(prayer: .isha, time: parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.yatsi, timeZone: timeZone))
        ]

        let referenceDate = try parseDate(day: todayEntry.miladiTarihKisaIso8601, timeString: todayEntry.ogle, timeZone: timeZone)

        return PrayerTimes(
            city: selection.city.name,
            country: selection.country.name,
            district: selection.district.name,
            districtID: selection.district.id,
            date: calendar.startOfDay(for: referenceDate),
            timeZoneIdentifier: timeZone.identifier,
            fetchedAt: Date(),
            prayers: entries
        )
    }

    private func bestDayMatch(in days: [DiyanetPrayerDay]) throws -> DiyanetPrayerDay {
        let now = Date()

        for day in days {
            guard let timeZone = Self.timeZone(from: day.miladiTarihUzunIso8601),
                  let date = Self.dateOnly(from: day.miladiTarihUzunIso8601) else {
                continue
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            if calendar.isDate(date, inSameDayAs: now) {
                return day
            }
        }

        guard let firstDay = days.first else {
            throw PrayerAPIServiceError.invalidData
        }

        return firstDay
    }

    private func parseDate(day: String, timeString: String, timeZone: TimeZone) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        guard let date = formatter.date(from: "\(day) \(timeString)") else {
            throw PrayerAPIServiceError.invalidData
        }

        return date
    }

    private func request<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw PrayerAPIServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw PrayerAPIServiceError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }

    private static func dateOnly(from isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString)
    }

    private static func timeZone(from isoString: String) -> TimeZone? {
        let suffix = String(isoString.suffix(6))
        guard suffix.count == 6 else { return nil }
        let sign: Int = suffix.hasPrefix("-") ? -1 : 1
        let hourString = String(suffix.dropFirst().prefix(2))
        let minuteString = String(suffix.suffix(2))
        guard let hours = Int(hourString), let minutes = Int(minuteString) else { return nil }
        return TimeZone(secondsFromGMT: sign * ((hours * 3600) + (minutes * 60)))
    }
}

enum PrayerAPIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case locationNotMatched

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not create the prayer API request."
        case .invalidResponse:
            return "The Diyanet prayer service returned an invalid response."
        case .invalidData:
            return "The prayer times returned by the Diyanet service could not be parsed."
        case .locationNotMatched:
            return "Could not match your location with a Diyanet city or district."
        }
    }
}
