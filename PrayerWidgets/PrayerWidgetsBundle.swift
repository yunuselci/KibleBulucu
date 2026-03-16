import WidgetKit
import SwiftUI

@main
@available(iOSApplicationExtension 17.0, *)
struct PrayerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextPrayerWidget()
        PrayerScheduleWidget()
    }
}
