# Location & Passport Mode Improvements — Design Spec

## Problem

1. **Pasaport modu belirsiz** — Aktif mi değil mi, gerçek konum vs pasaport konumu kullanıcıya net gösterilmiyor. Aktifleştirme/deaktifleştirme hataları düzgün handle edilmiyor.
2. **Konum güncellemesi yetersiz** — Sadece login + error state'de app resume'da güncelleniyor. Uzun süre açık kalan uygulamada konum eski kalabiliyor.
3. **Anti-spoofing yok** — VPN, emulator, mock location ile sahte konum gönderilebiliyor.

## Scope

- Client-only mock location detection (Yaklaşım 1 — geolocator `isMocked`)
- Throttled konum güncelleme (15dk interval)
- Pasaport UI iyileştirmeleri (discover badge, profil konum satırı, pasaport ekranı netleştirme)
- Hata mesajlarının lokalizasyonu

**Out of scope:**
- Server-side "imkansız hareket" tespiti (Yaklaşım 2 — future)
- SafetyNet / DeviceCheck entegrasyonu (Yaklaşım 3 — future)
- IP geolocation cross-check

## Architecture

### 1. Throttled Konum Güncelleme

**Dosya:** `lib/providers/location_provider.dart`

`LocationNotifier` içine:
- `DateTime? _lastUpdateTime` field eklenir
- `static const _kLocationUpdateInterval = Duration(minutes: 15)` sabiti eklenir
- `onAppResumed()` güncellenir:
  - **Mevcut:** Sadece error state varsa `getCurrentLocation()` çağrılır
  - **Yeni:** Error state VEYA `_lastUpdateTime`'dan 15+ dakika geçmişse `getCurrentLocation()` çağrılır
- `getCurrentLocation()` başarılı olduğunda `_lastUpdateTime = DateTime.now()` set edilir
- Cold start (login akışı) her zaman GPS alır, throttle uygulanmaz

**Sunucu:** Değişiklik yok — mevcut `PUT /users/me/location` endpoint'i aynen kullanılır.

### 2. Mock Location Tespiti

**Dosya:** `lib/core/services/location_manager.dart`

`getCurrentPosition()` içinde:
- `Position` alındıktan sonra `position.isMocked` kontrolü eklenir
- `kDebugMode` ise mock check atlanır (emulator'de development devam eder)
- Mock tespit edilirse `LocationResult` yerine özel hata döner

**Hata tipi:** `LOCATION_MOCK_DETECTED` — mevcut hata string pattern'ine uygun (`LOCATION_SERVICE_DISABLED`, `LOCATION_PERMISSION_DENIED` gibi)

**Dosya:** `lib/providers/location_provider.dart`

`getCurrentLocation()` içinde:
- `LOCATION_MOCK_DETECTED` hatası alınırsa state'e error olarak yazılır
- Konum sunucuya **gönderilmez** — eski DB konumu korunur

**Dosya:** `lib/features/discover/widgets/discover_location_error.dart` (veya mevcut hata widget'ı)

- `LOCATION_MOCK_DETECTED` hatası için özel mesaj: "Sahte konum algılandı. Gerçek konumunuzu kullanmanız gerekiyor."
- Buton gösterilmez — kullanıcı mock'u kapatıp geri döndüğünde `onAppResumed()` otomatik tekrar dener

**L10n key:** `location_mock_detected`

### 3. Pasaport UI İyileştirmesi

#### 3a. Discover Ekranı — Konum Badge'i

**Dosya:** Discover screen veya ilgili widget

- Discover üstünde konum chip'i eklenir/güncellenir:
  - Pasaport pasif: "📍 Istanbul"
  - Pasaport aktif: "✈️ Paris" (farklı renk — `AppColors.primaryDark`)
- Tıklanınca pasaport ekranına navigate eder
- Veri kaynağı: `locationProvider` (gerçek konum) + `passportProvider` (pasaport durumu)

#### 3b. Profil Ekranı — Konum Satırı

**Dosya:** Profil ekranı ilgili widget

- Mevcut profil bilgileri arasına konum bilgisi eklenir:
  - Pasaport pasif: "📍 Istanbul"
  - Pasaport aktif: "📍 Istanbul → ✈️ Paris"

#### 3c. Pasaport Ekranı — Durum Netleştirme

**Dosya:** `lib/features/passport/screens/passport_screen.dart`

- Aktifken: Belirgin yeşil/accent banner — "Pasaport aktif: {city}" + net "Deaktifleştir" butonu
- Hata mesajları lokalize:
  - `passport_activate_failed` — "Pasaport aktifleştirilemedi, tekrar deneyin"
  - `passport_deactivate_failed` — "Pasaport deaktifleştirilemedi"

#### 3d. PassportNotifier Sync

**Dosya:** `lib/providers/passport_provider.dart`

- Login akışında `syncFromUser()` çağrılarak pasaport state'i doğru yüklenir
- Bu sayede discover badge'i ilk açılışta doğru gösterilir

### 4. Yeni L10n Keys

| Key | TR | EN |
|-----|----|----|
| `location_mock_detected` | Sahte konum algılandı. Gerçek konumunuzu kullanmanız gerekiyor. | Fake location detected. Please use your real location. |
| `passport_activate_failed` | Pasaport aktifleştirilemedi, tekrar deneyin | Failed to activate passport, please try again |
| `passport_deactivate_failed` | Pasaport deaktifleştirilemedi | Failed to deactivate passport |
| `passport_active_label` | Pasaport aktif | Passport active |
| `location_current` | Mevcut Konum | Current Location |

## Data Flow

```
APP START / LOGIN:
  ├─ /users/me → seed locationProvider + passportProvider
  ├─ getCurrentLocation() (no throttle on login)
  │   ├─ isMocked? → REJECT, keep old location
  │   └─ real? → update state + POST /users/me/location
  └─ _lastUpdateTime = now

APP RESUME:
  ├─ error exists? → getCurrentLocation()
  ├─ 15+ min since last update? → getCurrentLocation()
  └─ otherwise → skip

DISCOVER:
  ├─ badge shows: passportProvider.isActive ? "✈️ {passport_city}" : "📍 {city}"
  └─ cards fetched using server-side passport_lat/lng ?? lat/lng (unchanged)

PASSPORT ACTIVATE:
  ├─ MapPickerScreen → select location
  ├─ POST /passport/activate {city, lat, lng}
  ├─ passportProvider.state updated → discover badge auto-updates
  └─ Error → snackbar passport_activate_failed
```

## Error States

| State | UI Behavior |
|-------|-------------|
| `LOCATION_MOCK_DETECTED` | DiscoverLocationError — uyarı mesajı, buton yok |
| `LOCATION_SERVICE_DISABLED` | Mevcut davranış — "Konum servisini aç" butonu |
| `LOCATION_PERMISSION_DENIED` | Mevcut davranış — "İzin ver" butonu |
| Passport activate failure | Snackbar: `passport_activate_failed` |
| Passport deactivate failure | Snackbar: `passport_deactivate_failed` |

## Files Changed

| File | Change |
|------|--------|
| `lib/providers/location_provider.dart` | Throttle logic + mock error handling |
| `lib/core/services/location_manager.dart` | `isMocked` check in getCurrentPosition |
| `lib/features/discover/` (widget) | Konum badge ekleme |
| `lib/features/passport/screens/passport_screen.dart` | UI netleştirme + hata lokalizasyonu |
| `lib/features/profile/` (widget) | Konum satırı ekleme |
| `lib/providers/passport_provider.dart` | syncFromUser doğrulaması |
| `lib/core/l10n/app_localizations.dart` | Yeni l10n keys |
| Discover location error widget | Mock detected mesajı |

## Testing

- Mock location tespiti: `kDebugMode` ile bypass, production'da aktif
- Throttle: 15dk'dan önce resume → skip, 15dk sonra → update
- Pasaport badge: aktif/pasif state değişiminde doğru gösterim
- Hata mesajları: tüm failure path'lerde lokalize mesaj gösterimi
