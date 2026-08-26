# Navratri 2026 - Nishitpark Society App

A Flutter application for Nishitpark Society's Navratri Mahotsav 2026 celebration.

## Features

- Splash Screen with animated logo
- Live countdown timer to Navratri 2026
- Digital QR Gate Pass
- Event schedule and Aarti booking
- WhatsApp pass sharing
- Beautiful Royal Gold & Purple theme

## Supported Platforms

- **Web** (Flutter Web)
- **Android**
- **iOS**

## Prerequisites

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Ensure Flutter is in your PATH
3. Run `flutter doctor` to verify setup

## Setup

1. Navigate to the project directory:
   ```bash
   cd navratri_app
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Ensure `BGIMAGE.png` is in `assets/images/` folder

## Running the App

### Web
```bash
flutter run -d chrome
```

### Android (requires Android Studio/emulator)
```bash
flutter run -d android
```

### iOS (requires macOS + Xcode)
```bash
flutter run -d ios
```

## Building for Production

### Web
```bash
flutter build web
```
Output: `build/web/` folder - can be hosted on any web server

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```
Then archive in Xcode for App Store deployment

## Project Structure

```
navratri_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── theme/
│   │   └── app_theme.dart     # Colors, gradients, theme data
│   ├── screens/
│   │   ├── splash_screen.dart # Animated splash screen
│   │   ├── home_screen.dart   # Main dashboard
│   │   └── gate_pass_screen.dart # QR gate pass
│   └── widgets/
│       ├── countdown_timer.dart # Live countdown
│       └── feature_card.dart   # Feature grid cards
├── assets/
│   └── images/
│       └── BGIMAGE.png        # Background image
├── web/
│   ├── index.html
│   └── manifest.json
└── pubspec.yaml
```

## Customization

- Edit `lib/theme/app_theme.dart` to change colors
- Update event dates in `home_screen.dart` (navratriStart variable)
- Modify QR pass data in `gate_pass_screen.dart`

## License

© 2026 Nishitpark Society Welfare Association
