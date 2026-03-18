import Foundation

struct Country: Codable, Equatable, Identifiable {
    let name: String
    let englishName: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case name = "UlkeAdi"
        case englishName = "UlkeAdiEn"
        case id = "UlkeID"
    }
}

struct City: Codable, Equatable, Identifiable {
    let name: String
    let englishName: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case name = "SehirAdi"
        case englishName = "SehirAdiEn"
        case id = "SehirID"
    }
}

struct District: Codable, Equatable, Identifiable {
    let name: String
    let englishName: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case name = "IlceAdi"
        case englishName = "IlceAdiEn"
        case id = "IlceID"
    }
}

struct PrayerLocationSelection: Codable, Equatable {
    let country: Country
    let city: City
    let district: District
    let isAutomatic: Bool

    static let defaultSelection = PrayerLocationSelection(
        country: Country(name: "TURKIYE", englishName: "TURKEY", id: "2"),
        city: City(name: "ISTANBUL", englishName: "ISTANBUL", id: "539"),
        district: District(name: "ISTANBUL", englishName: "ISTANBUL", id: "9541"),
        isAutomatic: false
    )

    var displayName: String {
        "\(district.name), \(city.name), \(country.name)"
    }

    var compactDisplayName: String {
        "\(city.name), \(country.name)"
    }
}

struct PrayerSettings: Codable, Equatable {
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var enabledPrayers: [Prayer: Bool]

    static let `default` = PrayerSettings(
        notificationsEnabled: false,
        soundEnabled: true,
        enabledPrayers: Dictionary(uniqueKeysWithValues: Prayer.allCases.map { ($0, true) })
    )

    func isEnabled(for prayer: Prayer) -> Bool {
        notificationsEnabled && (enabledPrayers[prayer] ?? true)
    }
}

struct PrayerTimes: Codable, Equatable {
    let city: String
    let country: String
    let district: String
    let districtID: String
    let date: Date
    let timeZoneIdentifier: String
    let fetchedAt: Date
    let prayers: [PrayerTimeEntry]
    let tomorrowFajrTime: Date?

    var sortedPrayers: [PrayerTimeEntry] {
        prayers.sorted { $0.time < $1.time }
    }

    var dayIdentifier: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func entry(for prayer: Prayer) -> PrayerTimeEntry? {
        prayers.first(where: { $0.prayer == prayer })
    }

    func isSameDay(as other: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        var calendarInZone = calendar
        calendarInZone.timeZone = timeZone
        return calendarInZone.isDate(date, inSameDayAs: other)
    }

    static var placeholder: PrayerTimes {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        let entries = [
            PrayerTimeEntry(prayer: .fajr, time: calendar.date(byAdding: .hour, value: 5, to: base) ?? base),
            PrayerTimeEntry(prayer: .sunrise, time: calendar.date(byAdding: .hour, value: 7, to: base) ?? base),
            PrayerTimeEntry(prayer: .dhuhr, time: calendar.date(byAdding: .hour, value: 13, to: base) ?? base),
            PrayerTimeEntry(prayer: .asr, time: calendar.date(byAdding: .hour, value: 16, to: base) ?? base),
            PrayerTimeEntry(prayer: .maghrib, time: calendar.date(byAdding: .hour, value: 19, to: base) ?? base),
            PrayerTimeEntry(prayer: .isha, time: calendar.date(byAdding: .hour, value: 20, to: base) ?? base)
        ]

        return PrayerTimes(
            city: "Istanbul",
            country: "Turkey",
            district: "Istanbul",
            districtID: "9541",
            date: base,
            timeZoneIdentifier: TimeZone.current.identifier,
            fetchedAt: Date(),
            prayers: entries,
            tomorrowFajrTime: nil
        )
    }
}
