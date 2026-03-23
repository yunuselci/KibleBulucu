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
        Task {
            let now = Date()
            let fetcher = WidgetPrayerFetcher()

            let wasStale = fetcher.isDataStale(at: now)
            if wasStale {
                try? await fetcher.fetchAndSave()
            }
            let isStillStale = wasStale && fetcher.isDataStale(at: now)

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

            let hasFuturePrayers = currentEntry.prayerTimes?.sortedPrayers.contains(where: { $0.time > now }) ?? false
            let refreshDate: Date
            if isStillStale {
                // Fetch failed (network error etc.) — retry in 30 minutes
                refreshDate = now.addingTimeInterval(30 * 60)
            } else if !hasFuturePrayers {
                // All today's prayers are done — wake at midnight to fetch the new day
                let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now)!)
                refreshDate = tomorrow.addingTimeInterval(60)
            } else {
                // Normal daytime operation — refresh every hour
                refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
            }

            completion(Timeline(entries: entries, policy: .after(refreshDate)))
        }
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
