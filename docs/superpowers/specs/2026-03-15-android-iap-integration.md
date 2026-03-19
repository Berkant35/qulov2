# Android IAP Integration - Google Play + RevenueCat

**Tarih:** 2026-03-15
**Durum:** Tamamlandi

## Ozet

iOS'ta calisan RevenueCat IAP sistemini Android (Google Play) icin de aktif hale getirdik. Backend zaten platform-agnostik oldugu icin sadece client konfigurasyonu ve store ayarlari yapildi.

## Yapilan Isler

### 1. Google Play Console

- **Uygulama ici urunler (Consumable)** — 6 adet:

| Urun Kimligi | Ad | Fiyat |
|---|---|---|
| qulopurple50 | 50 Mor Elmas | $0.99 |
| qulopurple150 | 150 Mor Elmas | $2.49 |
| qulopurple400 | 400 Mor Elmas | $4.99 |
| qulopurple1000 | 1000 Mor Elmas | $9.99 |
| qulopurple2500 | 2500 Mor Elmas | $19.99 |
| qulopurple6000 | 6000 Mor Elmas | $39.99 |

- **Abonelikler** — 2 adet:

| Urun Kimligi | Ad | Fiyat | Donem |
|---|---|---|---|
| quloplusmonthly2 | Qulo Plus | $4.99 | Aylik |
| qulopremiummonthly | Qulo Premium | $9.99 | Aylik |

- Etiketler: `diamonds`, `consumable`, `subscription`, `plus`, `premium`, `monthly`
- Satin alma secenegi kimlikleri: `<product>-otp` (consumable), `<plan>-monthly` (subscription)

### 2. Google Cloud + Service Account

- Service account: `revenuecatqulo@qulo-337719.iam.gserviceaccount.com`
- Google Play Console → Kullanicilar ve izinler → service account davet edildi
- Yetkiler: Finansal verileri goruntule, Siparisleri ve abonelikleri yonet
- JSON key RevenueCat'e yuklendi

### 3. RevenueCat Dashboard

- Google Play App eklendi (package: `com.wordpress.calikusuberkant.qulo`)
- Google API Key: `goog_tAQvpZTakPHMKEYCoFvjSpGmjmv`
- 8 urun tanimlandl (6 consumable + 2 subscription)
- Entitlements: `plus`, `premium`
- Offerings: iOS ve Android urunleri ayni offering altinda

### 4. Webhook

- URL: `https://qulo-server-production.up.railway.app/api/v1/webhooks/revenuecat`
- Auth: `Bearer rc_whsec_qulo_v2_2026`
- Environment: Both Production and Sandbox
- Events: All events (Initial Purchase, Renewal, Cancellation, Expiration, Product Change, Non-Renewing Purchase)

### 5. Flutter Kod Degisiklikleri

**`lib/core/config/env.dart`:**
- `revenueCatGoogleKey` default degeri eklendi

**`lib/core/services/revenuecat_service.dart`:**
- `purchaseByProductId()` metoduna `ProductCategory` parametresi eklendi
- Consumable urunler: `ProductCategory.nonSubscription`
- Subscription urunler: `ProductCategory.subscription`
- iOS'ta bu parametre gormezden gelinir, sadece Google Play icin gerekli

**`deploy.sh`:**
- `RC_APPLE_KEY` ve `RC_GOOGLE_KEY` degiskenleri eklendi
- APK ve IPA build'lerine `--dart-define` ile RevenueCat key'leri eklendi

**`.run/Local Dev.run.xml`:**
- `REVENUECAT_GOOGLE_KEY` dart-define eklendi

### 6. Keystore

- Dosya: `android/app/upload-keystore.jks`
- key.properties sifresi duzeltildi

## Mimari

```
Satin Alma Akisi (iki yollu):

1. Client → Backend (hizli yol):
   Kullanici satin alir
   → RevenueCat SDK (Google Play Billing)
   → Client backend'e POST /diamonds/purchase veya POST /subscriptions/activate
   → DB guncellenir, UI yenilenir

2. Webhook (arka plan):
   Apple/Google → RevenueCat → POST /webhooks/revenuecat
   → Yenileme, iptal, sure dolumu islemleri
   → Idempotency: transaction_id ile cift isleme onlenir
```

## Test

- Android: Dahili test track'ine APK yuklenmeli + test kullanicisi eklenmeli
- iOS: Debug modda Sandbox ile test edilebilir
- Google Play Billing sadece Play Store'dan yuklenen uygulamalarda calisir

## Kalan Isler

- [ ] Receipt validation (hardcoded 30 gun → gercek Apple/Google receipt dogrulama)
- [ ] deploy.sh'ta Production build icin Google key'in env var olarak alinmasi (guvenlik)
