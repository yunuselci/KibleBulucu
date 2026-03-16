import Foundation

struct DiyanetPrayerDay: Codable {
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
