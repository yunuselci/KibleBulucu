import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let settings: PrayerSettings
    let onNotificationsChanged: (Bool) -> Void
    let onSoundChanged: (Bool) -> Void
    let onPrayerToggleChanged: (Prayer, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "notifications_section_general")) {
                    Toggle(String(localized: "notifications_enable_prayer_notifications"), isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: onNotificationsChanged
                    ))

                    Toggle(String(localized: "notifications_play_default_sound"), isOn: Binding(
                        get: { settings.soundEnabled },
                        set: onSoundChanged
                    ))
                    .disabled(!settings.notificationsEnabled)
                }

                Section(String(localized: "notifications_section_individual_prayers")) {
                    ForEach(Prayer.allCases) { prayer in
                        Toggle(prayer.displayName, isOn: Binding(
                            get: { settings.enabledPrayers[prayer] ?? true },
                            set: { onPrayerToggleChanged(prayer, $0) }
                        ))
                        .disabled(!settings.notificationsEnabled)
                    }
                }
            }
            .navigationTitle(String(localized: "notifications_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common_done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView(
        settings: .default,
        onNotificationsChanged: { _ in },
        onSoundChanged: { _ in },
        onPrayerToggleChanged: { _, _ in }
    )
}
