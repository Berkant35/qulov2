# Mobile app — question-based dating

Flutter client for iOS and Android of a dating app where people match by answering each other's questions instead of swiping on photos. It is live on the App Store and Google Play.

## What's inside

- **18 feature modules** in `lib/features/`: onboarding, auth, discover, questions, quiz, chat, profile, in-app currency, notifications, settings and more
- **Riverpod** for state, **go_router** for navigation and deep links, typed **Dio / Retrofit** clients for the API
- **Supabase** and a Node.js API as the backend; **Firebase** for push notifications (FCM), Crashlytics and Analytics
- **RevenueCat** for subscriptions and in-app purchases, **Google Maps** for radius-based discovery
- **18 languages** through a custom translation layer in `lib/core/l10n/` (tests in `test/l10n/`)

## Project layout

```
lib/
  core/        theme, network, l10n, services, shared widgets and mixins
  data/        models and repositories
  features/    one folder per feature: screens, widgets, providers
  providers/   app-wide providers
  routing/     go_router configuration
test/          unit and widget tests, mirroring lib/
```

## Quality and delivery

- 850+ unit and widget tests
- GitHub Actions runs `dart analyze` and `flutter test` on every push, pinned to Flutter 3.35.3
- Releases go through fastlane lanes: TestFlight and Play internal testing first, then production

## Run it

```bash
flutter pub get
flutter test
flutter run
```

Requires Flutter 3.35 (Dart ^3.9).

---

Built and run end to end by [@Berkant35](https://github.com/Berkant35) — see also the [backend](https://github.com/Berkant35/qulo-server) and the [website](https://github.com/Berkant35/qulo_web).
