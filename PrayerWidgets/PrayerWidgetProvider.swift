import WidgetKit
import SwiftUI

struct PrayerWidgetProvider: TimelineProvider {
    private let store = WidgetDataProvider()

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(store.makeEntry(referenceDate: Date()) ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let currentEntry = store.makeEntry(referenceDate: now) ?? .placeholder
        var entries = [currentEntry]

        if let prayerTimes = currentEntry.prayerTimes {
            let futureEntries = prayerTimes.sortedPrayers
                .filter { $0.time > now }
                .map { prayer in
                    store.makeEntry(referenceDate: prayer.time.addingTimeInterval(1)) ?? currentEntry
                }

            entries.append(contentsOf: futureEntries)
        }

        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
}

struct WidgetDataProvider {
    private let defaults = UserDefaults(suiteName: "group.com.yunuselci.KibleBulucu") ?? .standard
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func makeEntry(referenceDate: Date) -> PrayerWidgetEntry? {
        guard let data = defaults.data(forKey: "stored_prayer_times"),
              let prayerTimes = try? decoder.decode(WidgetPrayerTimes.self, from: data) else {
            return nil
        }

        let nextPrayer = prayerTimes.sortedPrayers.first(where: { $0.time > referenceDate })
            ?? prayerTimes.tomorrowFajrTime.map { WidgetPrayerTimeEntry(prayer: .fajr, time: $0) }

        return PrayerWidgetEntry(
            date: referenceDate,
            prayerTimes: prayerTimes,
            nextPrayer: nextPrayer,
            countdownTarget: nextPrayer?.time
        )
    }
}
