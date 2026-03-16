import Foundation
import UserNotifications

final class NotificationManager {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() async throws -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        @unknown default:
            return false
        }
    }

    func rescheduleNotifications(for prayerTimes: PrayerTimes?, settings: PrayerSettings) async {
        await clearPrayerNotifications()

        guard let prayerTimes, settings.notificationsEnabled else { return }

        let requests = notificationRequests(for: prayerTimes, settings: settings)
        for request in requests {
            try? await center.add(request)
        }
    }

    func clearPrayerNotifications() async {
        let identifiers = Prayer.allCases.map(\.rawValue)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func notificationRequests(for prayerTimes: PrayerTimes, settings: PrayerSettings) -> [UNNotificationRequest] {
        let calendar = Calendar(identifier: .gregorian)

        return prayerTimes.sortedPrayers.compactMap { entry in
            guard settings.isEnabled(for: entry.prayer) else { return nil }
            guard entry.time > Date() else { return nil }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: entry.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = entry.prayer.displayName
            content.body = entry.prayer.notificationBody
            content.sound = settings.soundEnabled ? .default : nil

            return UNNotificationRequest(identifier: entry.prayer.rawValue, content: content, trigger: trigger)
        }
    }
}

private extension UNUserNotificationCenter {
    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }
}
