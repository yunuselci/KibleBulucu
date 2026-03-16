import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

final class PrayerStore {
    private enum Keys {
        static let prayerTimes = "stored_prayer_times"
        static let locationSelection = "stored_location_selection"
        static let prayerSettings = "stored_prayer_settings"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = UserDefaults(suiteName: AppGroupConfiguration.identifier)) {
        self.defaults = defaults ?? .standard
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadPrayerTimes() -> PrayerTimes? {
        loadValue(forKey: Keys.prayerTimes)
    }

    func savePrayerTimes(_ prayerTimes: PrayerTimes) {
        saveValue(prayerTimes, forKey: Keys.prayerTimes)
        reloadWidgets()
    }

    func loadLocationSelection() -> PrayerLocationSelection? {
        loadValue(forKey: Keys.locationSelection)
    }

    func saveLocationSelection(_ selection: PrayerLocationSelection?) {
        if let selection {
            saveValue(selection, forKey: Keys.locationSelection)
        } else {
            defaults.removeObject(forKey: Keys.locationSelection)
        }
        reloadWidgets()
    }

    func loadSettings() -> PrayerSettings {
        loadValue(forKey: Keys.prayerSettings) ?? .default
    }

    func saveSettings(_ settings: PrayerSettings) {
        saveValue(settings, forKey: Keys.prayerSettings)
        reloadWidgets()
    }

    private func saveValue<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func loadValue<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
