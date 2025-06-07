# Kıble Bulucu - Android

Android version of the Qibla Finder application, built with Jetpack Compose and Kotlin. This app helps Muslims find the direction of the Qibla (direction towards the Kaaba in Mecca) from their current location.

## Features

- 🧭 **Real-time Compass**: Shows Qibla direction with a rotating arrow
- 📍 **Location Services**: Uses GPS for accurate positioning
- 🔴/🟢 **Visual Feedback**: Arrow changes color when aligned with Qibla
- 📳 **Haptic Feedback**: Vibration when aligned with Qibla direction
- 🌍 **Precise Calculation**: Uses great circle navigation for accurate Qibla direction
- 🇹🇷 **Turkish Interface**: Full Turkish language support
- ⚡ **Smooth Animations**: Fluid arrow rotation and color transitions

## Technical Implementation

### Architecture
- **MVVM Pattern**: Using ViewModel and StateFlow for state management
- **Jetpack Compose**: Modern declarative UI framework
- **Coroutines**: For asynchronous operations
- **Location Services**: Google Play Services Location API
- **Sensors**: Android magnetometer and accelerometer for compass

### Core Components

#### 1. QiblaCalculator
Handles the mathematical calculation of Qibla direction using:
- Kaaba coordinates: 21.4225°N, 39.8262°E
- Great circle navigation formulas
- Angle normalization and formatting

#### 2. LocationManager
Manages location and compass functionality:
- GPS location updates with high accuracy
- Compass heading calculation using magnetometer and accelerometer
- Permission handling
- Error states and Turkish error messages

#### 3. CompassView
Jetpack Compose UI component featuring:
- Rotating arrow icon
- Color-coded alignment status (red/green)
- Smooth animations with 300ms duration
- 3-degree tolerance for alignment detection

#### 4. ContentView
Main screen layout including:
- Turkish header text
- Loading states
- Permission handling UI
- Location information display
- Error message handling

## Permissions Required

- `ACCESS_FINE_LOCATION`: For GPS location
- `ACCESS_COARSE_LOCATION`: Fallback location
- `VIBRATE`: For haptic feedback

## Hardware Requirements

- GPS capability
- Magnetometer sensor
- Accelerometer sensor

## Dependencies

- Jetpack Compose
- Google Play Services Location
- Accompanist Permissions
- Material Design 3
- Lifecycle components

## Building and Running

1. Open the project in Android Studio
2. Sync Gradle dependencies
3. Run on a physical device (recommended for best sensor accuracy)
4. Grant location permissions when prompted

## Accuracy Notes

- Best accuracy achieved on physical devices with quality sensors
- Device should be held flat and away from magnetic interference
- GPS accuracy depends on satellite signal strength
- Compass accuracy may vary based on device calibration

## Comparison with iOS Version

This Android implementation mirrors the iOS version feature-for-feature:

| Feature | iOS | Android |
|---------|-----|---------|
| Qibla Calculation | ✅ SwiftUI | ✅ Jetpack Compose |
| Location Services | ✅ CoreLocation | ✅ Google Play Services |
| Compass Integration | ✅ CLHeading | ✅ Sensor Fusion |
| Haptic Feedback | ✅ UIFeedback | ✅ Vibrator API |
| Smooth Animations | ✅ SwiftUI | ✅ Compose Animations |
| Turkish Language | ✅ | ✅ |
| Error Handling | ✅ | ✅ |
| Permission Management | ✅ | ✅ |

## Code Structure

```
app/src/main/java/com/yunuselci/KibleBulucu/
├── MainActivity.kt          # Main activity
├── ContentView.kt          # Main screen composable
├── CompassView.kt          # Compass UI component
├── LocationManager.kt      # Location and compass logic
├── QiblaCalculator.kt      # Qibla direction calculation
└── Preview.kt              # Compose previews
```

## Future Enhancements

- [ ] Dark/Light theme support
- [ ] Multiple language support
- [ ] Compass calibration guidance
- [ ] Prayer times integration
- [ ] Offline mode
- [ ] Widget support 