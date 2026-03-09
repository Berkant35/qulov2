# V1 to V2 Platform Migration Design

## Goal
Migrate all platform-specific configs (bundle IDs, Firebase, signing, assets, permissions, splash, fonts) from Qulo V1 to V2 so the app publishes as an update (v2.0.0) to existing store listings.

## Context
- V1 path: `/Users/berkantcalikusu/IdeaProjects/qulo_yedek`
- V2 path: `/Users/berkantcalikusu/IdeaProjects/qulov2`
- Same Firebase project: `qulo-b2f1a`
- Same bundle IDs (update, not new app)

## Decisions

### Bundle IDs (unchanged from V1)
- Android: `com.wordpress.calikusuberkant.qulo`
- iOS: `com.wordpress.calikusuberkant.qulorelease`
- Version: `2.0.0+28`

### Firebase (same project: qulo-b2f1a)
- Copy `google-services.json` from V1
- Copy `GoogleService-Info.plist` from V1
- Generate `firebase_options.dart` via `flutterfire configure`
- Only use: Crashlytics, Analytics, FCM

### Signing
- Copy `upload-keystore.jks` from V1
- Create `key.properties` with password `a159753789456123`

### Error Manager
- Global error handler: Flutter framework + async + zone errors
- Crashlytics auto-reporting
- User-friendly UI error display (SnackBar)
- Dio interceptor API error capture

### Permissions
- Android: camera, gallery, location (fine+coarse), internet
- iOS: camera, photo library, location (when in use + always)
- iOS: background modes (remote-notification, fetch)
- iOS: push notification entitlements
- iOS: localized permission strings (TR + EN via InfoPlist.strings)

### Assets & Fonts
- Copy from V1: logo, diamond icons, lottie, SVGs
- Font: Helvetica (download, place in assets/fonts/)
- Declare all in pubspec.yaml

### Splash & Icons
- Copy V1 app icon sets (Android adaptive + iOS asset catalog)
- Splash: purple gradient (#502989 -> #2A132E) via flutter_native_splash
- App label: "Qulo"

### Info.plist Localization
- `ios/Runner/tr.lproj/InfoPlist.strings` (Turkish)
- `ios/Runner/en.lproj/InfoPlist.strings` (English)
