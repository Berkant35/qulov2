# Qulo V2 - Dating App

## Project Structure
- **Mobile**: Flutter + Riverpod + GoRouter (lib/)
- **Backend**: Node.js + Express + TypeScript (server/)
- **DB**: Supabase PostgreSQL + PostGIS + Realtime
- **Auth**: Custom JWT (bcrypt + access/refresh tokens)
- **Firebase**: FCM (push), Crashlytics, Analytics

## Key Directories
- `lib/features/` — Feature-based Flutter modules (auth, discover, chat, profile, etc.)
- `lib/providers/` — Riverpod providers
- `lib/routing/` — GoRouter configuration
- `lib/core/` — Shared utilities, error handling, l10n
- `lib/core/navigation/` — NavigationService, observers, dialog/sheet models
- `lib/data/` — Models, repositories, API layer
- `server/src/routes/` — Express route modules
- `server/src/services/` — Business logic
- `server/src/middleware/` — Auth, rate limiting, validation

## Development Commands
- **Backend dev**: `cd server && npm run dev` (tsx watch)
- **Backend build**: `cd server && npm run build`
- **Flutter run**: `flutter run`
- **Flutter analyze**: `flutter analyze`
- **Tests**: `cd server && npm test` (vitest)

## Conventions
- Language: Turkish for communication, English for code
- Backend uses ESM (`"type": "module"`)
- Supabase uses service_role (RLS disabled)
- i18n: Custom AppLocalizations (lib/core/l10n/)
- State management: Riverpod (Notifier pattern)
- Routing: GoRouter with named routes, wrapped by NavigationService
- Navigation: Always use `ref.read(navigationServiceProvider)` — never direct GoRouter/Navigator calls in screens
- Dialogs: Use `ConfirmDialog`, `InfoDialog`, or `CustomDialog` via `NavigationService.showAppDialog()`
- BottomSheets: Use `ListBottomSheet` or `CustomBottomSheet` via `NavigationService.showAppBottomSheet()`
- API base URL configured via environment

## Hardware/Device Package Rule
- Donanımsal paketler (image_picker, geolocator, url_launcher, firebase_messaging vb.) ASLA doğrudan ekranlarda/widget'larda kullanılmaz
- Her paket için `lib/core/services/` altında singleton manager oluştur (ör. `ImagePickerManager.instance`)
- Manager'a `lib/providers/api_provider.dart`'ta Riverpod provider tanımla
- Feature'lardan sadece provider üzerinden eriş: `ref.read(imagePickerManagerProvider)`
- Mevcut manager'lar: `ImagePickerManager`, `LocationManager`, `UrlLauncherManager`, `NotificationManager`

## Notification System
- **Backend**: NotificationService her bildirimi `notifications` tablosuna yazar + FCM push gönderir
- **Bildirim tipleri**: new_message, new_message_image, new_match, quiz_started, passport_expired, campaign
- **action_url**: Her bildirimde deep link — Flutter'da GoRouter ile navigate edilir
- **Flutter**: NotificationManager (singleton) → NotificationNotifier (provider) → login sonrası auto-init
- **Inbox**: `/profile/notifications` route'u, profile ekranında çan ikonu + unread badge
- **In-App Banner**: Foreground'da gelen bildirimler üstten kayan banner ile gösterilir (lib/core/widgets/in_app_banner.dart)
- **Kampanya sistemi**: Backoffice'ten segment bazlı hedefli bildirim gönderimi
  - Segment filtreleri: cinsiyet, yaş, şehir, abonelik, aktiflik, profil tamamlanma, kayıt tarihi
  - Admin routes: `/admin/campaigns` (liste, oluştur, detay, gönder, iptal)
  - Analitik: targeted/sent/delivered/opened/clicked + segment breakdown
- **DB tabloları**: notifications, campaigns, campaign_stats, campaign_events (migration 009)

## Loading Widget Kuralı
- **ASLA** `CircularProgressIndicator` kullanma — her yerde `AppLoadingWidget` kullan
- **Tam sayfa loading**: `AppScaffold(isLoading: true, body: ...)` — body yerine otomatik Q logo loading gösterir
- **Inline / buton içi loading**: `AppLoadingWidget.small()` (24px, sadece spin)
- **Section loading**: `AppLoadingWidget.large()` (48px, spin + mor neon glow)
- Riverpod `.when(loading: ...)` pattern'i → AppScaffold `isLoading: state is AsyncLoading` ile kullan, loading callback'te `SizedBox.shrink()` dön
- Widget dosyası: `lib/core/widgets/app_loading_widget.dart`

## Design & Component Rules
- UI bileşenleri her zaman ortak komponent olarak yazılmalı (lib/core/widgets/)
- Tüm renkler, text style'lar, spacing'ler theme dosyasından gelmeli — hardcoded değer kullanma
- Hata mesajları inline gösterilmeli (input altında kırmızı yazı)
- Tasarımsal değişikliklerde önce theme'i güncelle, sonra widget'ı yaz
- Yeni widget = önce lib/core/widgets/'a ortak komponent, sonra feature'da kullan

## Diamonds & IAP System
- **Monetizasyon**: Tüm monetizasyon mor elmas ekonomisi üzerinden — süper beğeni YOK
- **IAP**: RevenueCat entegrasyonu (purchases_flutter ^8.5.0)
- **API key güvenliği**: `--dart-define` env vars ile, hardcoded değil (`lib/core/config/env.dart`)
- **Consumable ürünler** (6 adet): qulopurple50/150/400/1000/2500/6000
- **Subscription** (2 tier): Qulo Plus ($4.99/ay, quloplusmonthly2), Qulo Premium ($9.99/ay, qulopremiummonthly)
- **Plus özellikleri**: 500 mor elmas/ay, sınırsız keşif, 6 soru slotu, 3 undo/gün, reklam yok
- **Premium özellikleri**: 1500 mor elmas/ay, sınırsız keşif, 10 soru slotu, sınırsız undo, pasaport modu, reklam yok
- **Free limitler**: 50 keşif/gün, 4 soru slotu, undo yok, reklam var
- **Webhook**: Apple → RevenueCat → Backend (`POST /api/v1/webhooks/revenuecat`) → Supabase
- **Backend routes**: `/api/v1/webhooks` (webhook.routes.ts), `/api/v1/subscriptions` (subscription.routes.ts)
- **Backend services**: subscription.service.ts, webhook.service.ts
- **DB tabloları**: user_subscriptions, iap_transactions (migration 008 — çalıştırıldı)
- **Flutter dosyaları**:
  - Service: `lib/core/services/revenuecat_service.dart`, `lib/core/services/upsell_service.dart`
  - Models: `lib/data/models/subscription_model.dart`, `lib/data/models/diamond_model.dart`
  - Providers: `lib/providers/subscription_provider.dart`, `lib/providers/diamond_provider.dart`
  - Screens: `lib/features/diamonds/screens/diamonds_screen.dart`, `subscription_comparison_screen.dart`
  - Widgets: `diamond_balance_card.dart`, `subscription_banner.dart`, `purchase_grid.dart`, `upsell_sheets.dart`
- **Tasarım kararları**:
  - Purchase grid: Yığılmış elmas tasarımı (DiamondTier enum, tier başına 1-6 elmas üst üste)
  - DiamondIcon: Her yerde `showGlow: true` (default) — duman efekti varsayılan
  - Subscription kartlarında elmas ikonu olarak DiamondIcon.purple kullanılır (QIcon/icGem değil)
  - Balance card: Mor ve yeşil elmaslar duman efektli gösterilir
- **Upsell sistemi**: 6 trigger (onboarding, diamond_empty, first_match, swipe_limit, day_3, boost_need), session başına max 2, SharedPreferences cooldown
- **Kalan işler**: Migration 008 çalıştırma, RevenueCat entitlements/offerings kurulumu, webhook URL ayarlama, Google Play ürün oluşturma

## Important Notes
- Never commit .env files
- Supabase migrations run manually via SQL Editor
- Firebase config files are in the repo (firebase_options.dart, google-services.json, GoogleService-Info.plist)
