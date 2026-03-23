import Foundation

// Local copy of the Diyanet API response model (mirrors KibleBulucu/Models/DiyanetPrayerDay.swift)
private struct DiyanetPrayerDay: Decodable {
    let miladiTarihKisaIso8601: String
    let miladiTarihUzunIso8601: String
    let aksam: String
    let gunes: String
    let ikindi: String
    let imsak: String
    let ogle: String
    let yatsi: String

    enum CodingKeys: String, CodingKey {
        case miladiTarihKisaIso8601 = "MiladiTarihKisaIso8601"
        case miladiTarihUzunIso8601 = "MiladiTarihUzunIso8601"
        case aksam = "Aksam"
        case gunes = "Gunes"
        case ikindi = "Ikindi"
        case imsak = "Imsak"
        case ogle = "Ogle"
        case yatsi = "Yatsi"
    }
}

struct WidgetPrayerFetcher {
    private let defaults = UserDefaults(suiteName: "group.com.yunuselci.KibleBulucu") ?? .standard
    private let baseURL = URL(string: "https://ezanvakti.emushaf.net")!

    // Minimal decoders — only the districtID is needed to call the API
    private struct StoredDistrict: Decodable {
        let id: String
        enum CodingKeys: String, CodingKey { case id = "IlceID" }
    }
    private struct StoredLocationSelection: Decodable {
        let district: StoredDistrict
    }

    func isDataStale(at now: Date) -> Bool {
        guard let data = defaults.data(forKey: "stored_prayer_times") else { return true }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let prayerTimes = try? decoder.decode(WidgetPrayerTimes.self, from: data) else { return true }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: prayerTimes.timeZoneIdentifier) ?? .current
        return !calendar.isDate(prayerTimes.date, inSameDayAs: now)
    }

    func fetchAndSave() async throws {
        guard let locData = defaults.data(forKey: "stored_location_selection"),
              let location = try? JSONDecoder().decode(StoredLocationSelection.self, from: locData) else {
            return
        }

        let url = baseURL.appendingPathComponent("vakitler/\(location.district.id)")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            return
        }

        let days = try JSONDecoder().decode([DiyanetPrayerDay].self, from: data)
        guard let prayerTimes = mapToWidgetPrayerTimes(days: days) else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(prayerTimes) else { return }
        defaults.set(encoded, forKey: "stored_prayer_times")
    }

    private func mapToWidgetPrayerTimes(days: [DiyanetPrayerDay]) -> WidgetPrayerTimes? {
        let now = Date()

        guard let todayEntry = days.first(where: { day in
            guard let tz = Self.timeZone(from: day.miladiTarihUzunIso8601),
                  let date = Self.dateOnly(from: day.miladiTarihUzunIso8601) else { return false }
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz
            return cal.isDate(date, inSameDayAs: now)
        }) ?? days.first else { return nil }

        let timeZone = Self.timeZone(from: todayEntry.miladiTarihUzunIso8601) ?? .current

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        func parse(_ time: String) -> Date? {
            formatter.date(from: "\(todayEntry.miladiTarihKisaIso8601) \(time)")
        }

        guard let fajr = parse(todayEntry.imsak),
              let sunrise = parse(todayEntry.gunes),
              let dhuhr = parse(todayEntry.ogle),
              let asr = parse(todayEntry.ikindi),
              let maghrib = parse(todayEntry.aksam),
              let isha = parse(todayEntry.yatsi) else { return nil }

        let prayers = [
            WidgetPrayerTimeEntry(prayer: .fajr, time: fajr),
            WidgetPrayerTimeEntry(prayer: .sunrise, time: sunrise),
            WidgetPrayerTimeEntry(prayer: .dhuhr, time: dhuhr),
            WidgetPrayerTimeEntry(prayer: .asr, time: asr),
            WidgetPrayerTimeEntry(prayer: .maghrib, time: maghrib),
            WidgetPrayerTimeEntry(prayer: .isha, time: isha)
        ]

        let tomorrowFajr: Date? = {
            guard let idx = days.firstIndex(where: { $0.miladiTarihKisaIso8601 == todayEntry.miladiTarihKisaIso8601 }),
                  days.indices.contains(idx + 1) else { return nil }
            let tomorrow = days[idx + 1]
            let tzTomorrow = Self.timeZone(from: tomorrow.miladiTarihUzunIso8601) ?? timeZone
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = tzTomorrow
            fmt.dateFormat = "dd.MM.yyyy HH:mm"
            return fmt.date(from: "\(tomorrow.miladiTarihKisaIso8601) \(tomorrow.imsak)")
        }()

        // Carry over city/country from previously stored data (unchanged between daily refreshes)
        let (city, country) = storedCityCountry()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return WidgetPrayerTimes(
            city: city,
            country: country,
            date: calendar.startOfDay(for: dhuhr),
            timeZoneIdentifier: timeZone.identifier,
            fetchedAt: now,
            prayers: prayers,
            tomorrowFajrTime: tomorrowFajr
        )
    }

    private func storedCityCountry() -> (city: String, country: String) {
        guard let data = defaults.data(forKey: "stored_prayer_times") else { return ("", "") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let stored = try? decoder.decode(WidgetPrayerTimes.self, from: data) else { return ("", "") }
        return (stored.city, stored.country)
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

    private static func dateOnly(from isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString)
    }
}
