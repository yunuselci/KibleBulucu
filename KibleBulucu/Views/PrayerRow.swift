import SwiftUI

struct PrayerRow: View {
    let entry: PrayerTimeEntry
    let isNext: Bool

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.prayer.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isNext ? .white : Color.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isNext ? Color.accentColor : Color.accentColor.opacity(0.12))
                )

            Text(entry.prayer.displayName)
                .font(.headline)
                .foregroundStyle(isNext ? .white : .primary)

            Spacer()

            Text(Self.formatter.string(from: entry.time))
                .font(.headline.monospacedDigit())
                .foregroundStyle(isNext ? .white : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isNext ? Color.accentColor : Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    PrayerRow(
        entry: PrayerTimes.placeholder.sortedPrayers[0],
        isNext: true
    )
    .padding()
}
