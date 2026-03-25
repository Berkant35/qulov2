# Location & Passport Mode Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mock location tespiti + throttled konum güncellemesi + pasaport UI iyileştirmesi ile konum sistemini güvenilir ve kullanıcı dostu hale getirmek.

**Architecture:** LocationManager'a `isMocked` kontrolü eklenir, LocationNotifier'a 15dk throttle eklenir, discover/profil/pasaport ekranlarında konum bilgisi netleştirilir. Sunucu değişikliği yok.

**Tech Stack:** Flutter, Riverpod, geolocator (isMocked), geocoding, AppLocalizations

---

## File Structure

| File | Responsibility | Change Type |
|------|---------------|-------------|
| `lib/core/services/location_manager.dart` | GPS + mock detection | Modify |
| `lib/providers/location_provider.dart` | Throttle + mock error handling | Modify |
| `lib/features/discover/widgets/discover_location_error.dart` | Mock detected UI + retry | Modify |
| `lib/features/discover/widgets/passport_badge.dart` | Konum badge (passport + gerçek konum) | Modify |
| `lib/features/passport/screens/passport_screen.dart` | Hata lokalizasyonu | Modify |
| `lib/features/profile/widgets/detail_chips.dart` | Konum chip ekleme | Modify |
| `lib/core/l10n/app_localizations.dart` | Yeni l10n keys | Modify |

---

### Task 1: L10n Keys Ekleme

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

- [ ] **Step 1: Yeni l10n key'lerini ekle**

`_tr` map'ine (General bölümünden sonra) şu key'leri ekle:

```dart
// Location
'location_mock_detected': 'Sahte konum algılandı. Gerçek konumunuzu kullanmanız gerekiyor.',
'location_retry': 'Tekrar Dene',
'location_current': 'Mevcut Konum',

// Passport errors
'passport_activate_failed': 'Pasaport aktifleştirilemedi, tekrar deneyin',
'passport_deactivate_failed': 'Pasaport deaktifleştirilemedi',
'passport_active_label': 'Pasaport aktif',
```

`_en` map'ine de aynı key'lerin İngilizce karşılıklarını ekle:

```dart
'location_mock_detected': 'Fake location detected. Please use your real location.',
'location_retry': 'Try Again',
'location_current': 'Current Location',
'passport_activate_failed': 'Failed to activate passport, please try again',
'passport_deactivate_failed': 'Failed to deactivate passport',
'passport_active_label': 'Passport active',
```

- [ ] **Step 2: Analyze et**

Run: `dart analyze lib/core/l10n/app_localizations.dart`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add l10n keys for location mock detection and passport errors"
```

---

### Task 2: Mock Location Tespiti — LocationManager

**Files:**
- Modify: `lib/core/services/location_manager.dart`

**Bağlam:** `LocationManager.getCurrentPosition()` şu an `Geolocator.getCurrentPosition()` çağırıp `LocationResult` döndürüyor. Mock tespiti burada eklenmeli.

- [ ] **Step 1: foundation import'u ekle**

Dosyanın başına ekle:
```dart
import 'package:flutter/foundation.dart';
```

- [ ] **Step 2: Exception class'ı ekle**

`LocationResult` class'ından sonra, `LocationManager` class'ından önce ekle:

```dart
class MockLocationException implements Exception {
  const MockLocationException();
  @override
  String toString() => 'LOCATION_MOCK_DETECTED';
}
```

- [ ] **Step 3: getCurrentPosition'a mock check ekle**

Mevcut `getCurrentPosition()` metodunu güncelle:

```dart
Future<LocationResult> getCurrentPosition() async {
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );

  // Mock location check — only in release mode (kDebugMode bypasses for emulator testing)
  if (!kDebugMode && position.isMocked) {
    throw const MockLocationException();
  }

  final city = await getCityFromCoordinates(position.latitude, position.longitude);
  return LocationResult(lat: position.latitude, lng: position.longitude, city: city);
}
```

- [ ] **Step 4: Analyze et**

Run: `dart analyze lib/core/services/location_manager.dart`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/location_manager.dart
git commit -m "feat: add mock location detection to LocationManager"
```

---

### Task 3: Throttled Konum Güncelleme — LocationNotifier

**Files:**
- Modify: `lib/providers/location_provider.dart`

**Bağlam:** `LocationNotifier` şu an `onAppResumed()`'da sadece error varsa retry yapıyor. Throttle eklenmeli + mock error handle edilmeli.

- [ ] **Step 1: LocationNotifier'a throttle field'ları ekle**

Not: `location_manager.dart` zaten `api_provider.dart` üzerinden import ediliyor. `MockLocationException` bu import'tan erişilebilir, ek import gerekmez.

`LocationNotifier` class'ının içine, `build()` metodundan önce ekle:

```dart
DateTime? _lastUpdateTime;
static const _kLocationUpdateInterval = Duration(minutes: 15);
```

- [ ] **Step 2: onAppResumed'ı güncelle**

Mevcut `onAppResumed()` metodunu şu şekilde değiştir:

```dart
/// App resume olduğunda çağrılır.
/// Error varsa veya 15dk geçmişse konum güncellenir.
void onAppResumed() {
  if (state.isLoading) return;

  // Error varsa her zaman retry
  if (state.error != null) {
    getCurrentLocation();
    return;
  }

  // Throttle: son güncellemeden 15dk geçmişse güncelle
  if (_lastUpdateTime == null ||
      DateTime.now().difference(_lastUpdateTime!) >= _kLocationUpdateInterval) {
    getCurrentLocation();
  }
}
```

- [ ] **Step 3: getCurrentLocation'da mock error handling + lastUpdateTime**

Mevcut `getCurrentLocation()` metodunu şu şekilde değiştir:

```dart
Future<void> getCurrentLocation() async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    final manager = ref.read(locationManagerProvider);

    final serviceEnabled = await manager.isServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(isLoading: false, error: 'LOCATION_SERVICE_DISABLED');
      return;
    }

    var permission = await manager.checkPermission();
    if (permission == LocationPermissionStatus.denied) {
      permission = await manager.requestPermission();
      if (permission == LocationPermissionStatus.denied) {
        state = state.copyWith(isLoading: false, error: 'LOCATION_PERMISSION_DENIED');
        return;
      }
    }

    if (permission == LocationPermissionStatus.deniedForever) {
      state = state.copyWith(isLoading: false, error: 'LOCATION_PERMISSION_DENIED_FOREVER');
      return;
    }

    final result = await manager.getCurrentPosition();

    state = state.copyWith(
      lat: result.lat,
      lng: result.lng,
      city: result.city,
      isLoading: false,
    );

    _lastUpdateTime = DateTime.now();

    await ref.read(userRepositoryProvider).updateLocation(
      lat: result.lat,
      lng: result.lng,
      city: result.city,
    );
  } on MockLocationException {
    state = state.copyWith(isLoading: false, error: 'LOCATION_MOCK_DETECTED');
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}
```

- [ ] **Step 4: Analyze et**

Run: `dart analyze lib/providers/location_provider.dart`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/providers/location_provider.dart
git commit -m "feat: add 15min throttled location updates and mock detection error handling"
```

---

### Task 4: DiscoverLocationError — Mock Detected UI

**Files:**
- Modify: `lib/features/discover/widgets/discover_location_error.dart`

**Bağlam:** Mevcut widget her hata tipinde aynı buton gösteriyor (ayarları aç). Mock detected için farklı mesaj + "Tekrar Dene" butonu lazım.

- [ ] **Step 1: Import ekle**

```dart
import 'package:qulo_v2/providers/location_provider.dart';
```

- [ ] **Step 2: Widget'ı hata tipine göre farklılaştır**

Mevcut `build` metodunu şu şekilde değiştir:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final isMockError = error == 'LOCATION_MOCK_DETECTED';

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMockError ? Icons.gps_off : Icons.location_off,
            size: 64,
            color: isMockError ? AppColors.error : AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isMockError
                ? context.tr('location_mock_detected')
                : context.tr('location_required'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (!isMockError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('location_required_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () async {
                if (isMockError) {
                  ref.read(locationProvider.notifier).getCurrentLocation();
                } else {
                  final manager = ref.read(locationManagerProvider);
                  if (error == 'LOCATION_SERVICE_DISABLED') {
                    await manager.openLocationSettings();
                  } else {
                    await manager.openAppSettings();
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isMockError ? AppColors.error : AppColors.primaryDark,
              ),
              child: Text(
                isMockError
                    ? context.tr('location_retry')
                    : context.tr('enable_location'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Analyze et**

Run: `dart analyze lib/features/discover/widgets/discover_location_error.dart`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/features/discover/widgets/discover_location_error.dart
git commit -m "feat: add mock location detected UI with retry button"
```

---

### Task 5: PassportBadge — Konum Gösterimi Genişletme

**Files:**
- Modify: `lib/features/discover/widgets/passport_badge.dart`

**Bağlam:** Şu an sadece pasaport aktifken gösteriliyor. Her zaman gösterilmeli — pasaport pasifken gerçek şehir, aktifken pasaport şehri.

- [ ] **Step 1: Import ekle ve widget'ı güncelle**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PassportBadge extends ConsumerWidget {
  const PassportBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passport = ref.watch(passportProvider);
    final location = ref.watch(locationProvider);
    final isPassportActive = passport.isActive;
    final city = isPassportActive ? passport.city : location.city;

    if (city == null || city.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => ref.read(navigationServiceProvider).push(RouteNames.passport),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: isPassportActive ? AppColors.primarySurface : AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isPassportActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPassportActive ? Icons.flight : Icons.location_on,
                size: 14,
                color: isPassportActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                city,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPassportActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze et**

Run: `dart analyze lib/features/discover/widgets/passport_badge.dart`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/discover/widgets/passport_badge.dart
git commit -m "feat: show location badge always — city when passport off, destination when on"
```

---

### Task 6: Pasaport Ekranı — Hata Lokalizasyonu

**Files:**
- Modify: `lib/features/passport/screens/passport_screen.dart`

**Bağlam:** Mevcut ekranda aktivasyon/deaktivasyon hataları `error_try_again` olarak gösteriliyor. Spesifik hata mesajları eklenecek.

- [ ] **Step 1: activate hata handling'i güncelle**

`_openMapPicker()` metodunda `withLoading` çağrısını şu şekilde değiştir:

Mevcut:
```dart
await withLoading(() async {
  await ref.read(passportProvider.notifier).activate(city: city, lat: lat, lng: lng);
});
```

Yeni (analytics logunu success bloğuna taşı — mevcut kodda withLoading sonrasında ayrı çağrılıyor, burada birleştiriyoruz):
```dart
await withLoading(() async {
  final result = await ref.read(passportProvider.notifier).activate(city: city, lat: lat, lng: lng);
  result.when(
    success: (_) {
      _analytics.logEvent(AnalyticsEvents.passportActivate, params: {
        AnalyticsEvents.paramDestinationCity: city,
      });
    },
    failure: (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('passport_activate_failed'))),
        );
      }
    },
  );
});
```

Ayrıca `withLoading` çağrısından sonraki mevcut analytics satırlarını kaldır (artık success bloğunun içinde):
```dart
// Bu satırları SİL:
_analytics.logEvent(AnalyticsEvents.passportActivate, params: {
  AnalyticsEvents.paramDestinationCity: city,
});
```

- [ ] **Step 2: deactivate hata handling'i güncelle**

Mevcut deactivate `onPressed` callback'ini güncelle:

Mevcut:
```dart
withLoading(() => ref.read(passportProvider.notifier).deactivate()).then((_) {
  _analytics.logEvent(AnalyticsEvents.passportDeactivate, params: {
    AnalyticsEvents.paramDestinationCity: city,
  });
});
```

Yeni:
```dart
withLoading(() async {
  final result = await ref.read(passportProvider.notifier).deactivate();
  result.when(
    success: (_) {
      _analytics.logEvent(AnalyticsEvents.passportDeactivate, params: {
        AnalyticsEvents.paramDestinationCity: city,
      });
    },
    failure: (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('passport_deactivate_failed'))),
        );
      }
    },
  );
});
```

- [ ] **Step 3: Mevcut genel error text'ini kaldır**

Dosyanın sonundaki `passport.failure != null` bloğunu kaldır (artık snackbar ile gösteriliyor):

Kaldırılacak:
```dart
if (passport.failure != null) ...[
  const SizedBox(height: AppSpacing.md),
  Text(
    context.tr('error_try_again'),
    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
    textAlign: TextAlign.center,
  ),
],
```

- [ ] **Step 4: Analyze et**

Run: `dart analyze lib/features/passport/screens/passport_screen.dart`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/passport/screens/passport_screen.dart
git commit -m "feat: localize passport activate/deactivate error messages"
```

---

### Task 7: Profil — Konum Chip Ekleme

**Files:**
- Modify: `lib/features/profile/widgets/detail_chips.dart`

**Bağlam:** `DetailChips` widget'ı kullanıcı detaylarını chip olarak gösteriyor. Konum bilgisi chip olarak eklenmeli — pasaport aktifse "Istanbul → Paris" formatında.

**Önemli:** `DetailChips` widget'ı hem kendi profilinde hem başka kullanıcıların profilinde kullanılıyor. Konum chip'i sadece kendi profilimizde gösterilmeli — başka kullanıcının profilinde `locationProvider`/`passportProvider` (kendi state'imiz) göstermek yanlış olur. Bu yüzden `isOwnProfile` parametresi ekliyoruz.

- [ ] **Step 1: Import ekle**

Dosyanın başına ekle:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
```

- [ ] **Step 2: Widget'ı ConsumerWidget'a çevir ve isOwnProfile parametresi ekle**

`DetailChips` class'ını `StatelessWidget`'tan `ConsumerWidget`'a çevir ve `isOwnProfile` parametresi ekle:

```dart
class DetailChips extends ConsumerWidget {
  final UserModel user;
  final bool isOwnProfile;
  final VoidCallback? onTap;

  const DetailChips({
    super.key,
    required this.user,
    this.isOwnProfile = false,
    this.onTap,
  });
```

`build` metodu imzasını güncelle:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
```

**Çağıran yerleri güncelle:** `DetailChips` widget'ının kullanıldığı yerlerde kendi profil ekranından çağrılıyorsa `isOwnProfile: true` geçilmeli. Implementer `DetailChips` kullanımlarını grep'le bulup güncellemeli.

- [ ] **Step 3: Konum chip'ini chips listesinin başına ekle (sadece kendi profil)**

`build` metodu içinde, `final chips = <_ChipData>[` satırından önce konum bilgisini hazırla ve chip listesinin başına ekle:

```dart
String? locationLabel;
if (isOwnProfile) {
  final passport = ref.watch(passportProvider);
  final location = ref.watch(locationProvider);
  locationLabel = passport.isActive && passport.city != null
      ? '${location.city ?? "?"} → ${passport.city}'
      : location.city;
}

final chips = <_ChipData>[
  if (locationLabel != null && locationLabel.isNotEmpty)
    _ChipData(
      icon: QIcons.icLocation,
      filled: true,
      label: locationLabel,
    ),
  // ... mevcut chip'ler aynen devam
```

`isOwnProfile == false` ise `ref.watch` çağrılmaz — gereksiz provider subscription'ı önlenir. `QIcons.icLocation` mevcuttur (q_icons.dart:76).

- [ ] **Step 4: Analyze et**

Run: `dart analyze lib/features/profile/widgets/detail_chips.dart`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/widgets/detail_chips.dart
git commit -m "feat: add location chip to profile detail chips with passport info"
```

---

### Task 8: PassportNotifier syncFromUser Doğrulaması

**Files:**
- Verify: `lib/providers/auth_provider.dart` (veya login flow dosyası)
- Verify: `lib/providers/passport_provider.dart`

**Bağlam:** Spec, login akışında `syncFromUser()` çağrılmasını gerektiriyor. Mevcut kodda bu çağrı zaten olabilir. Doğrulanması ve yoksa eklenmesi gerekiyor.

- [ ] **Step 1: Login akışında syncFromUser çağrısını doğrula**

`auth_provider.dart` dosyasında (veya `checkAuth()` metodunda) `passportProvider.notifier.syncFromUser()` çağrısını ara.

Mevcut kodda zaten varsa → bu adımı atla.

Yoksa, `seedFromProfile()` çağrısının hemen altına ekle:

```dart
// Passport state'i sync et
final passportCity = user.passportCity;
ref.read(passportProvider.notifier).syncFromUser(
  passportCity,
  user.passportLat,
  user.passportLng,
);
```

**Not:** `UserModel`'da `passportCity`, `passportLat`, `passportLng` field'larının varlığını kontrol et. Yoksa user model'dan gelen data'ya göre uyarla.

- [ ] **Step 2: Analyze et**

Run: `dart analyze lib/providers/auth_provider.dart`
Expected: 0 issues

- [ ] **Step 3: Commit (sadece değişiklik yaptıysan)**

```bash
git add lib/providers/auth_provider.dart
git commit -m "feat: ensure passport state is synced from user profile on login"
```

---

### Task 9: Full Analyze + Manuel Test Kontrol Listesi

**Files:** Tüm değiştirilmiş dosyalar

- [ ] **Step 1: Full analyze çalıştır**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 2: Kalan hataları düzelt**

Varsa hataları düzelt ve tekrar analyze et.

- [ ] **Step 3: Manuel test kontrol listesi**

Aşağıdakileri test edin:

1. **Throttle:** App'i aç → GPS güncellenmeli. Background'a at, 5dk sonra foreground'a getir → GPS güncellenmemeli. 15dk sonra foreground'a getir → GPS güncellenmeli.
2. **Mock detection (Android):** Mock location app aktifken app'i aç → "Sahte konum algılandı" mesajı görünmeli, "Tekrar Dene" butonu olmalı. Mock'u kapat, "Tekrar Dene" → konum güncellenmeli.
3. **Debug mode:** Emulator'de debug build → mock check atlanmalı, normal çalışmalı.
4. **Discover badge:** Pasaport pasifken "📍 Istanbul" gösterilmeli. Pasaport aktifken "✈️ Paris" gösterilmeli. Badge'a tıklanınca pasaport ekranı açılmalı.
5. **Profil konum chip:** Pasaport pasifken "Istanbul" chip'i görünmeli. Pasaport aktifken "Istanbul → Paris" görünmeli.
6. **Pasaport hata mesajları:** Aktivasyon hatası → "Pasaport aktifleştirilemedi, tekrar deneyin" snackbar. Deaktivasyon hatası → "Pasaport deaktifleştirilemedi" snackbar.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "fix: resolve any remaining analyze issues for location & passport improvements"
```
