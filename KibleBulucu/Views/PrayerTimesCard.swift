import SwiftUI

struct PrayerTimesCard: View {
    let cityName: String
    let dateText: String
    let currentPrayer: Prayer?
    let nextPrayer: PrayerTimeEntry?
    let countdownText: String
    let prayerTimes: PrayerTimes?
    let isLoading: Bool
    let onRefresh: () -> Void
    let onSelectCity: () -> Void
    let onNotifications: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(cityName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Menu {
                    Button(String(localized: "prayer_menu_change_location"), action: onSelectCity)
                    Button(String(localized: "prayer_menu_notifications"), action: onNotifications)
                    Button(String(localized: "prayer_menu_refresh"), action: onRefresh)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }

            Group {
                if nextPrayer != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("prayer_time_until_label")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))

                        Text(countdownText)
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("prayer_day_complete_title")
                            .font(.title3.weight(.semibold))
                        Text("prayer_day_complete_message")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if isLoading {
                ProgressView("prayer_times_loading")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let prayerTimes {
                VStack(spacing: 10) {
                    ForEach(prayerTimes.sortedPrayers) { entry in
                        PrayerRow(entry: entry, isNext: currentPrayer == entry.prayer)
                    }
                }
            } else if !isLoading {
                Text("prayer_times_unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
    }
}

#Preview {
    PrayerTimesCard(
        cityName: "Istanbul, Turkey",
        dateText: DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none),
        currentPrayer: .asr,
        nextPrayer: PrayerTimes.placeholder.sortedPrayers[4],
        countdownText: "01:24:10",
        prayerTimes: PrayerTimes.placeholder,
        isLoading: false,
        onRefresh: {},
        onSelectCity: {},
        onNotifications: {}
    )
    .padding()
}
