import WidgetKit
import Foundation

enum WidgetPrayer: String, CaseIterable, Codable, Identifiable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fajr:    return "İmsak"
        case .sunrise: return "Güneş"
        case .dhuhr:   return "Öğle"
        case .asr:     return "İkindi"
        case .maghrib: return "Akşam"
        case .isha:    return "Yatsı"
        }
    }

    var symbolName: String {
        switch self {
        case .fajr:
            return "moon.stars.fill"
        case .sunrise:
            return "sunrise.fill"
        case .dhuhr:
            return "sun.max.fill"
        case .asr:
            return "sun.haze.fill"
        case .maghrib:
            return "sunset.fill"
        case .isha:
            return "sparkles"
        }
    }
}

enum WidgetLocale {
    static func text(_ english: String, turkish: String) -> String {
        turkish
    }
}

struct WidgetPrayerTimeEntry: Codable, Identifiable {
    let prayer: WidgetPrayer
    let time: Date

    var id: WidgetPrayer { prayer }
}

struct WidgetPrayerTimes: Codable {
    let city: String
    let country: String
    let date: Date
    let timeZoneIdentifier: String
    let fetchedAt: Date
    let prayers: [WidgetPrayerTimeEntry]

    var sortedPrayers: [WidgetPrayerTimeEntry] {
        prayers.sorted { $0.time < $1.time }
    }
}

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let prayerTimes: WidgetPrayerTimes?
    let nextPrayer: WidgetPrayerTimeEntry?
    let countdownTarget: Date?

    static var placeholder: PrayerWidgetEntry {
        let now = Date()
        let base = Calendar.current.startOfDay(for: now)
        let prayers = [
            WidgetPrayerTimeEntry(prayer: .fajr, time: Calendar.current.date(byAdding: .hour, value: 5, to: base) ?? now),
            WidgetPrayerTimeEntry(prayer: .sunrise, time: Calendar.current.date(byAdding: .hour, value: 7, to: base) ?? now),
            WidgetPrayerTimeEntry(prayer: .dhuhr, time: Calendar.current.date(byAdding: .hour, value: 13, to: base) ?? now),
            WidgetPrayerTimeEntry(prayer: .asr, time: Calendar.current.date(byAdding: .hour, value: 16, to: base) ?? now),
            WidgetPrayerTimeEntry(prayer: .maghrib, time: Calendar.current.date(byAdding: .hour, value: 19, to: base) ?? now),
            WidgetPrayerTimeEntry(prayer: .isha, time: Calendar.current.date(byAdding: .hour, value: 20, to: base) ?? now)
        ]

        let prayerTimes = WidgetPrayerTimes(
            city: "Istanbul",
            country: "Turkey",
            date: now,
            timeZoneIdentifier: TimeZone.current.identifier,
            fetchedAt: now,
            prayers: prayers
        )

        return PrayerWidgetEntry(
            date: now,
            prayerTimes: prayerTimes,
            nextPrayer: prayers.first(where: { $0.time > now }) ?? prayers[0],
            countdownTarget: prayers.first(where: { $0.time > now })?.time
        )
    }
}
