import Foundation
import Combine

struct CountdownSnapshot: Equatable {
    let nextPrayer: PrayerTimeEntry?
    let currentPrayer: Prayer?
    let remainingTimeText: String
}

final class CountdownManager: ObservableObject {
    @Published private(set) var nextPrayer: PrayerTimeEntry?
    @Published private(set) var currentPrayer: Prayer?
    @Published private(set) var remainingTimeText = "--:--:--"

    private var timerCancellable: AnyCancellable?
    private var prayerTimes: PrayerTimes?

    func start(with prayerTimes: PrayerTimes?) {
        self.prayerTimes = prayerTimes
        recalculate(for: Date())

        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.recalculate(for: date)
            }
    }

    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func recalculate(for now: Date) {
        guard let prayerTimes else {
            nextPrayer = nil
            currentPrayer = nil
            remainingTimeText = "--:--:--"
            return
        }

        let snapshot = Self.snapshot(for: prayerTimes, at: now)
        nextPrayer = snapshot.nextPrayer
        currentPrayer = snapshot.currentPrayer
        remainingTimeText = snapshot.remainingTimeText
    }

    static func snapshot(for prayerTimes: PrayerTimes, at now: Date) -> CountdownSnapshot {
        let sorted = prayerTimes.sortedPrayers

        let nextPrayer = sorted.first(where: { $0.time > now })

        if let nextPrayer {
            let previousIndex = sorted.firstIndex(where: { $0.prayer == nextPrayer.prayer }).map { $0 - 1 }
            let currentPrayer = previousIndex.flatMap { sorted.indices.contains($0) ? sorted[$0].prayer : nil }

            return CountdownSnapshot(
                nextPrayer: nextPrayer,
                currentPrayer: currentPrayer,
                remainingTimeText: format(interval: nextPrayer.time.timeIntervalSince(now))
            )
        }

        if let tomorrowFajr = prayerTimes.tomorrowFajrTime {
            let tomorrowEntry = PrayerTimeEntry(prayer: .fajr, time: tomorrowFajr)
            return CountdownSnapshot(
                nextPrayer: tomorrowEntry,
                currentPrayer: sorted.last?.prayer,
                remainingTimeText: format(interval: tomorrowFajr.timeIntervalSince(now))
            )
        }

        return CountdownSnapshot(
            nextPrayer: nil,
            currentPrayer: sorted.last?.prayer,
            remainingTimeText: "Completed"
        )
    }

    static func format(interval: TimeInterval) -> String {
        let totalSeconds = max(Int(interval.rounded(.down)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
