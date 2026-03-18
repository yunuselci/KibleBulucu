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
                Section("Genel") {
                    Toggle("Namaz Bildirimlerini Aç", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: onNotificationsChanged
                    ))

                    Toggle("Varsayılan Bildirim Sesini Çal", isOn: Binding(
                        get: { settings.soundEnabled },
                        set: onSoundChanged
                    ))
                    .disabled(!settings.notificationsEnabled)
                }

                Section("Tek Tek Namazlar") {
                    ForEach(Prayer.allCases) { prayer in
                        Toggle(prayer.displayName, isOn: Binding(
                            get: { settings.enabledPrayers[prayer] ?? true },
                            set: { onPrayerToggleChanged(prayer, $0) }
                        ))
                        .disabled(!settings.notificationsEnabled)
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bitti") {
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
