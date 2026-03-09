# App Version & Force Update Sistemi — Tasarım

## Kararlar
- Versiyon bilgisi: Supabase tablosu (app_config)
- Platform: iOS ve Android ayrı min/latest version
- Force update: Hibrit (splash → full-screen, onResume → dialog)
- Opsiyonel güncelleme: Dismiss + 24 saat akıllı erteleme
- Bakım modu: Var (is_maintenance + message)
- Store linkleri: Backend'den dinamik

## 1. Supabase Tablosu: `app_config`

| Kolon | Tip | Açıklama |
|---|---|---|
| id | uuid (PK) | Tek satır |
| min_version_ios | text | Force update eşiği (iOS) |
| min_version_android | text | Force update eşiği (Android) |
| latest_version_ios | text | Güncel versiyon (iOS) |
| latest_version_android | text | Güncel versiyon (Android) |
| store_url_ios | text | App Store linki |
| store_url_android | text | Google Play linki |
| is_maintenance | boolean | Bakım modu flag |
| maintenance_message_tr | text | Bakım mesajı (TR) |
| maintenance_message_en | text | Bakım mesajı (EN) |
| is_force_update_enabled | boolean | Force update açık/kapalı (kill switch) |
| updated_at | timestamptz | Son güncelleme |

Tek satırlık config tablosu. Default: min_version = 2.0.0, latest_version = 2.0.0.

## 2. Backend Endpoint

**GET /api/v1/app/config** — Auth gerektirmez

Request headers: `x-app-platform: ios|android`, `x-app-version: 2.0.0`

Response:
```json
{
  "minVersion": "2.0.0",
  "latestVersion": "2.1.0",
  "storeUrl": "https://apps.apple.com/...",
  "isMaintenance": false,
  "maintenanceMessage": null,
  "isForceUpdateEnabled": true
}
```

Platform'a göre doğru alanları döner.

## 3. Mobil Akış

### A) Splash sonrası (ilk kontrol)
1. Splash animasyonu biter
2. GET /app/config
3. Maintenance aktif → Full-screen maintenance sayfası (blocking)
4. Force gerekli (version < minVersion && isForceUpdateEnabled) → Full-screen force update sayfası (blocking)
5. Opsiyonel güncelleme (version < latestVersion) → 24s erteleme kontrolü → Dismiss edilebilir dialog
6. Temiz → Normal auth flow'a devam

### B) onResume (lifecycle)
1. App ön plana gelir
2. GET /app/config
3. Maintenance aktif → Non-dismissable dialog
4. Force gerekli → Non-dismissable dialog ("Güncelle" butonu)
5. Opsiyonel → Gösterme (sadece splash'te)

## 4. Edge Case Yönetimi

| Edge Case | Çözüm |
|---|---|
| Store'dan geri dönüş (güncelleme yapmadan) | onResume tekrar kontrol → dialog tekrar açılır |
| Network hatası (endpoint'e ulaşılamıyor) | Sessizce geç, uygulamayı bloklamaz |
| is_force_update_enabled = false | Force update devre dışı, min_version kontrol edilmez |
| Dialog üstünde dialog (çift tetikleme) | Flag: _isUpdateDialogShown |
| Pop-up dismiss (onPause → geri gelince) | onResume her seferinde endpoint'i çeker |
| Backoffice'den anlık force açma | Kullanıcı onResume'da yakalar |

## 5. UI Bileşenleri

- **ForceUpdateScreen** — Full-screen, logo + mesaj + "Güncelle" butonu. WillPopScope ile geri engelli.
- **MaintenanceScreen** — Full-screen, bakım ikonu + mesaj. Buton yok.
- **OptionalUpdateDialog** — ConfirmDialog pattern. "Güncelle" + "Daha Sonra".

## 6. Dosya Yapısı

```
server/src/routes/app.routes.ts
server/src/services/app.service.ts

lib/data/models/app_config_model.dart
lib/data/repositories/app_config_repository.dart
lib/providers/app_config_provider.dart
lib/core/services/version_checker.dart
lib/features/update/force_update_screen.dart
lib/features/update/maintenance_screen.dart
```
