import WidgetKit
import SwiftUI

@available(iOSApplicationExtension 17.0, *)
struct NextPrayerWidget: Widget {
    let kind = "NextPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            SmallPrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
        .description("Shows the upcoming prayer and the remaining countdown.")
        .supportedFamilies([.systemSmall])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct PrayerScheduleWidget: Widget {
    let kind = "PrayerScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            MediumPrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Schedule")
        .description("Shows today's prayers and highlights the next one.")
        .supportedFamilies([.systemMedium])
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct SmallPrayerWidgetView: View {
    let entry: PrayerWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WidgetSurface(colorScheme: colorScheme, contentPadding: 16) {
            if entry.prayerTimes != nil {
                VStack(alignment: .leading, spacing: 10) {
                    if let nextPrayer = entry.nextPrayer {
                        Spacer(minLength: 0)
                        PrayerBadge(prayer: nextPrayer.prayer, palette: palette)

                        Text(nextPrayer.prayer.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(palette.primaryText)
                            .lineLimit(1)

                        Text(Self.timeFormatter.string(from: nextPrayer.time))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.secondaryText)

                        Divider()
                            .overlay(palette.divider)

                        Text(nextPrayer.time, style: .timer)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(palette.primaryText)
                            .contentTransition(.numericText(countsDown: true))
                    } else if let lastPrayer = entry.prayerTimes?.sortedPrayers.last {
                        Spacer(minLength: 0)
                        PrayerBadge(prayer: lastPrayer.prayer, palette: palette)

                        Text(lastPrayer.prayer.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(palette.primaryText)
                            .lineLimit(1)

                        Text(Self.timeFormatter.string(from: lastPrayer.time))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.secondaryText)

                        Divider()
                            .overlay(palette.divider)

                        Text(lastPrayer.time, style: .timer)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(palette.primaryText)
                            .contentTransition(.numericText(countsDown: false))
                    }
                }
            } else {
                WidgetEmptyState(
                    title: WidgetLocale.text("Prayer Times", turkish: "Namaz Vakitleri"),
                    message: WidgetLocale.text("Open the app to load today's schedule.", turkish: "Bugünün vakitlerini yüklemek için uygulamayı açın."),
                    palette: palette
                )
            }
        }
    }

    private var palette: WidgetPalette {
        WidgetPalette(colorScheme: colorScheme)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

@available(iOSApplicationExtension 17.0, *)
private struct MediumPrayerWidgetView: View {
    let entry: PrayerWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WidgetSurface(colorScheme: colorScheme, contentPadding: 10) {
            if let prayerTimes = entry.prayerTimes {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {

                        VStack(alignment: .leading, spacing: 2) {
                            Text(prayerTimes.city)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.primaryText)

                            Text(Self.dateFormatter.string(from: prayerTimes.date))
                                .font(.footnote)
                                .foregroundStyle(palette.secondaryText)
                        }

                        Spacer()

                        let timerPrayer = entry.nextPrayer ?? prayerTimes.sortedPrayers.last
                        if let timerPrayer {
                            let isCountingDown = entry.nextPrayer != nil
                            VStack(alignment: .trailing, spacing: 2) {

                                Text(isCountingDown ? "Vaktin Çıkmasına" : "Son Vakitten Beri")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(palette.primaryText)

                                Text(timerPrayer.time, style: .timer)
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .monospacedDigit()
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(palette.secondaryText)
                            }
                        }
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 6),
                            GridItem(.flexible(), spacing: 6),
                            GridItem(.flexible(), spacing: 6)
                        ],
                        spacing: 6
                    ) {
                        ForEach(prayerTimes.sortedPrayers.prefix(6)) { prayer in
                            PrayerGridTile(
                                prayer: prayer,
                                isHighlighted: prayerTimes.sortedPrayers.last(where: { $0.time <= entry.date })?.prayer == prayer.prayer,
                                palette: palette
                            )
                        }
                    }
                }
            } else {
                WidgetEmptyState(
                    title: WidgetLocale.text("Prayer Times", turkish: "Namaz Vakitleri"),
                    message: WidgetLocale.text("Open the app to load today's schedule.", turkish: "Bugünün vakitlerini yüklemek için uygulamayı açın."),
                    palette: palette
                )
            }
        }
    }

    private var palette: WidgetPalette {
        WidgetPalette(colorScheme: colorScheme)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.setLocalizedDateFormatFromTemplate("d MMMM EEEE")
        return formatter
    }()
}

@available(iOSApplicationExtension 17.0, *)
private struct PrayerGridTile: View {
    let prayer: WidgetPrayerTimeEntry
    let isHighlighted: Bool
    let palette: WidgetPalette

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: prayer.prayer.symbolName)
                .font(.subheadline)
                .foregroundStyle(isHighlighted ? .white : palette.secondaryText)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(prayer.prayer.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isHighlighted ? .white : palette.primaryText)
                    .lineLimit(1)

                Text(Self.timeFormatter.string(from: prayer.time))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isHighlighted ? Color.white.opacity(0.85) : palette.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHighlighted ? palette.tileHighlightFill : palette.cardFill)
        )
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

@available(iOSApplicationExtension 17.0, *)
private struct PrayerBadge: View {
    let prayer: WidgetPrayer
    let palette: WidgetPalette

    var body: some View {
        Label(prayer.displayName, systemImage: prayer.symbolName)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(palette.badgeText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(palette.badgeFill, in: Capsule())
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct WidgetEyebrow: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct WidgetEmptyState: View {
    let title: String
    let message: String
    let palette: WidgetPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetEyebrow(title: title, tint: palette.accent)
            Spacer(minLength: 0)
            Image(systemName: "clock.badge.questionmark")
                .font(.title3)
                .foregroundStyle(palette.secondaryText)
            Text(message)
                .font(.footnote)
                .foregroundStyle(palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct WidgetSurface<Content: View>: View {
    let colorScheme: ColorScheme
    let contentPadding: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(contentPadding)
            .containerBackground(for: .widget) {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(WidgetPalette(colorScheme: colorScheme).backgroundGradient)
            }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct WidgetPalette {
    let colorScheme: ColorScheme

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.10, green: 0.14, blue: 0.22), Color(red: 0.16, green: 0.27, blue: 0.38)]
                : [Color(red: 0.92, green: 0.96, blue: 1.0), Color(red: 0.84, green: 0.90, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var primaryText: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.11, green: 0.15, blue: 0.22)
    }

    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : Color(red: 0.28, green: 0.35, blue: 0.44)
    }

    var accent: Color {
        colorScheme == .dark ? Color(red: 0.76, green: 0.86, blue: 1.0) : Color(red: 0.20, green: 0.40, blue: 0.72)
    }

    var tileHighlightFill: Color {
        colorScheme == .dark ? Color(red: 0.22, green: 0.44, blue: 0.78) : accent
    }

    var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.70)
    }

    var highlightFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.92)
    }

    var highlightStroke: Color {
        accent.opacity(colorScheme == .dark ? 0.35 : 0.22)
    }

    var badgeFill: Color {
        colorScheme == .dark ? accent.opacity(0.16) : accent.opacity(0.12)
    }

    var badgeText: Color {
        accent
    }

    var divider: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
}
