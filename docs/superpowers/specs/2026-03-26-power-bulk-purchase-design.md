# Power Bulk Purchase — Sheet Kapanmadan Tekrarli Alim

**Tarih:** 2026-03-26
**Durum:** Onaylandi

## Problem

Kullanici bir ozel guc satin aldiginda bottom sheet otomatik kapaniyor. Birden fazla guc almak isteyen kullanici her seferinde sheet'i tekrar acmak zorunda kaliyor — UX surtusmesi yasiyor.

## Cozum

Satin alma sonrasi sheet kapanmaz. Bakiye ve envanter aninda guncellenir (Riverpod reactivity). Kullanici istedigini alip sheet'i kendisi kapatir. Basarili alim aninda sayac uzerinde scale-up + glow pulse animasyonu oynar.

## Yaklasim

**Tekrarli tek basis (B):** Mevcut "Al" butonu kalir, her basista 1 adet alir ama sheet kapanmaz. UI'a dokunulmaz, sadece `pop()` kaldirilir ve basari animasyonu eklenir.

## Etkilenen Dosyalar

| Dosya | Degisiklik |
|-------|-----------|
| `features/quiz/widgets/power_purchase_sheet.dart` | Basari sonrasi `pop()` kaldir, animasyon ekle |
| `features/exchange/widgets/power_shop_card.dart` | Ayni pattern — basari sonrasi kapanma yok |
| Quiz ekranindaki guc satin alma (varsa) | Ayni pattern |

## Detayli Akis

### Basarili Satin Alma (degisen)

1. Kullanici "Al" butonuna basar
2. Loading spinner gosterilir (mevcut `_buyingKey` mekanizmasi — double-tap korumasi)
3. `buyPower()` basarili donus yapar
4. `exchangeProvider.fetchAll()` + `diamondProvider.fetchBalance()` tetiklenir
5. **Sheet KAPANMAZ** — bakiye ustte, envanter sayisi guc satirlarinda aninda guncellenir
6. Sayac uzerinde **scale-up + yesil glow pulse** animasyonu oynar (basari feedback'i)
7. Kullanici isterse baska guc alir, isterse sheet'i kendisi kapatir

### Insufficient Diamonds (degismiyor)

1. Server `INSUFFICIENT_DIAMONDS` hatasi doner
2. Sheet kapanir (`pop()`)
3. Paywall bottom sheet acilir (diamond satin alma upsell)
4. Bu akis aynen kalir — kullanici zaten alamiyor, diamond satin almasi lazim

### Diger Hatalar (degismiyor)

1. SnackBar ile hata mesaji gosterilir
2. Sheet acik kalir (zaten mevcut davranis)

## Basari Animasyonu

Sayac (`xN`) degistiginde tetiklenir:

- **Scale-up:** Sayac 1.0 → 1.3 → 1.0 (200ms, easeOutBack)
- **Glow pulse:** Sayac etrafinda power'in kendi rengiyle (PowerType.color) kisa bir glow efekti (opacity 0 → 0.6 → 0, 300ms)
- Animasyon `AnimationController` ile tetiklenir, `didUpdateWidget` veya Riverpod state degisiminde baslatilir
- Hafif ve sade — abartili degil ama fark edilir

## API Degisikligi

Yok. `POST /exchange/buy-power` mevcut haliyle `quantity: 1` gondermeye devam eder. Her buton basisi ayri bir API call'dir.

## Model Degisikligi

Yok.

## Provider Degisikligi

Yok. Mevcut `exchangeProvider.buyPower()` + `fetchAll()` + `fetchBalance()` zinciri aynen calisir.

## Dokunulmayan Seyler

- API endpoint'leri
- Model siniflari (PowerModel, ExchangeRatePower, BuyPowerResponse)
- Provider logic (ExchangeNotifier, DiamondNotifier)
- Double-tap korumasi (`_buyingKey`)
- Paywall/upsell akisi
- PowerIcon widget'i (animasyon sheet icinde sayac uzerinde, icon'da degil)
