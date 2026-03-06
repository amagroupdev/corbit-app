# ORBIT SMS V3 - iOS Migration Guide

## Prerequisites (Mac)

- macOS Ventura or later
- Xcode 15.2+ (install from App Store)
- Flutter SDK 3.10.7+ (`flutter --version` to check)
- CocoaPods (`sudo gem install cocoapods`)

## Step 1: Clone the Repository

```bash
git clone https://github.com/amagroupdev/corbit-app.git
cd corbit-app
```

## Step 2: Install Dependencies

```bash
flutter pub get
```

## Step 3: iOS Pod Install

```bash
cd ios
pod install
cd ..
```

If pod install fails, try:
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
cd ..
```

## Step 4: Firebase Setup (Required)

Before building, you need to add the Firebase config files:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Download `GoogleService-Info.plist` for iOS
3. Place it at: `ios/Runner/GoogleService-Info.plist`

Without this file, the app will crash on launch (FirebaseApp.configure() in AppDelegate.swift).

## Step 5: Open in Xcode

```bash
open ios/Runner.xcworkspace
```

**Important:** Always open `.xcworkspace`, NOT `.xcodeproj`.

## Step 6: Configure Signing

1. In Xcode, select the `Runner` target
2. Go to **Signing & Capabilities** tab
3. Select your **Team** (Apple Developer account)
4. Xcode will auto-manage signing (or set manual if using enterprise cert)

Bundle Identifier: `com.orbit.orbitApp`

## Step 7: Build & Run

```bash
# Run on simulator
flutter run

# Build release IPA
flutter build ios --release

# Or archive from Xcode:
# Product > Archive
```

## Step 8: Archive for App Store / TestFlight

1. In Xcode: **Product > Archive**
2. Once archive completes, click **Distribute App**
3. Choose **App Store Connect** (or Ad Hoc for testing)
4. Upload to TestFlight or submit for review

## Project Configuration Summary

| Setting | Value |
|---------|-------|
| Bundle ID (iOS) | `com.orbit.orbitApp` |
| Bundle ID (Android) | `com.orbit.orbit_app` |
| Display Name | ORBIT SMS |
| iOS Deployment Target | 13.0 |
| Flutter SDK | ^3.10.7 |
| API Base URL | `https://app.mobile.net.sa/api/v3` |

## Key Plugins Requiring iOS Config

| Plugin | iOS Requirement |
|--------|----------------|
| `image_picker` | Camera & Photo Library permissions (already in Info.plist) |
| `firebase_messaging` | Push notification capability + GoogleService-Info.plist |
| `firebase_core` | GoogleService-Info.plist |
| `flutter_secure_storage` | Keychain sharing (auto-configured) |
| `permission_handler` | Permissions already declared in Info.plist |
| `webview_flutter` | Works out of the box on iOS |

## Troubleshooting

### "Module 'Firebase' not found"
```bash
cd ios && pod install --repo-update && cd ..
```

### "Signing requires a development team"
Select your team in Xcode > Runner > Signing & Capabilities.

### "deployment target too low" warnings
The Podfile post_install hook forces all pods to iOS 13.0. If a pod requires higher, update the `platform :ios` line in `ios/Podfile`.

### Clean build if something is stuck
```bash
flutter clean
flutter pub get
cd ios && pod deintegrate && pod install && cd ..
flutter build ios
```
