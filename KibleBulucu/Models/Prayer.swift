import Foundation

enum Prayer: String, CaseIterable, Codable, Identifiable {
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

    var iconName: String {
        switch self {
        case .fajr:
            return "sparkles"
        case .sunrise:
            return "sunrise"
        case .dhuhr:
            return "sun.max"
        case .asr:
            return "sun.haze"
        case .maghrib:
            return "sunset"
        case .isha:
            return "moon.stars"
        }
    }

    var notificationBody: String {
        "\(displayName) vakti girdi"
    }
}

struct PrayerTimeEntry: Codable, Identifiable, Hashable {
    let prayer: Prayer
    let time: Date

    var id: Prayer { prayer }
}
