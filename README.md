# Kıble Bulucu - Qibla Direction Finder

A minimal, production-ready iOS application built with SwiftUI that helps users find the Qibla direction (towards Mecca) based on their current location and compass heading.

## 🕌 Features

- **Real-time Qibla Direction**: Calculates accurate Qibla direction using your GPS location
- **Simple Arrow Interface**: Clean, centered arrow that rotates to point toward Qibla
- **Live Rotation**: Arrow smoothly rotates as you turn your device based on compass heading
- **Location Display**: Shows current latitude and longitude coordinates
- **Minimal Design**: Clean, Apple-compliant interface following HIG 2025 standards
- **Dark Mode Support**: Automatically adapts to system appearance settings

## 📱 Requirements

- iOS 16.0+
- Xcode 16.0+
- Swift 5.0+
- Device with GPS and magnetometer (compass)

## 🚀 Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/KibleBulucu.git
   cd KibleBulucu
   ```

2. Open `KibleBulucu.xcodeproj` in Xcode

3. Select your development team in the project settings

4. Build and run on a physical device (required for location and compass features)

## 🔧 Project Structure

```
KibleBulucu/
├── KibleBulucuApp.swift       # App entry point
├── ContentView.swift          # Main UI view with simplified layout
├── LocationManager.swift      # Core Location and heading management
├── QiblaCalculator.swift      # Qibla direction calculation logic
├── CompassView.swift          # Simple rotating arrow component
└── Assets.xcassets/           # App icons and assets
```

## 🧮 Qibla Calculation

The app uses the following mathematical formula to calculate the Qibla direction:

```swift
let kaabaLatitude = 21.4225   // Kaaba coordinates
let kaabaLongitude = 39.8262

let deltaLon = kaabaLongitude - userLongitude
let y = sin(deltaLon * π / 180)
let x = cos(userLatitude * π / 180) * tan(kaabaLatitude * π / 180) - 
        sin(userLatitude * π / 180) * cos(deltaLon * π / 180)

let qiblaDirection = atan2(y, x) * 180 / π
let normalizedDirection = (qiblaDirection + 360) % 360
```

## 🔐 Permissions

The app requires the following permissions (configured in project settings):

- **Location When In Use**: To determine your current position
- **Device Capabilities**: Location services and magnetometer access

Permission descriptions:
- `NSLocationWhenInUseUsageDescription`: "Your location is required to determine the Qibla direction."

## 🎨 User Interface

- **Header**: App title and subtitle
- **Central Arrow**: Large, green SF Symbol arrow (`arrow.up.circle.fill`) that rotates to point toward Qibla
- **Direction Info**: Qibla bearing displayed below the arrow
- **Location Info**: Current coordinates and directional description
- **Loading State**: Progress indicator while acquiring location
- **Error Handling**: User-friendly error messages

## 🔄 Live Updates

The app provides real-time updates for:
- GPS location changes
- Compass heading changes
- Arrow rotation: `rotation = qiblaDirection - currentHeading`
- Smooth animations with 0.3 second easing

## 🏪 App Store Ready

This project is configured for App Store submission:

- ✅ Follows Apple Human Interface Guidelines
- ✅ Proper privacy permissions
- ✅ Clean, minimal design
- ✅ No third-party dependencies
- ✅ Production-ready code structure
- ✅ Bundle identifier: `com.yunuselci.KibleBulucu`
- ✅ iOS 16.0+ deployment target

## 🧪 Testing

The project includes:
- Unit test target: `KibleBulucuTests`
- UI test target: `KibleBulucuUITests`

To run tests:
1. Open the project in Xcode
2. Press `Cmd+U` to run all tests
3. Use the Test Navigator to run specific tests

## 🔨 Building

To build the project:

```bash
xcodebuild -project KibleBulucu.xcodeproj -scheme KibleBulucu -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' clean build
```

Or simply open in Xcode and press `Cmd+B` to build.

## 📝 License

This project is available under the MIT License. See the LICENSE file for more info.

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions, please open an issue in this repository.

---

**Built with ❤️ using SwiftUI and Core Location** 