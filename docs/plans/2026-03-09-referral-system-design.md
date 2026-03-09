# Referral System Design — Arkadaşını Getir, Mor Elmas Kap

**Tarih:** 2026-03-09
**Durum:** Onaylandı

## Özet

Kullanıcılar arkadaşlarını davet eder, arkadaş kayıt olup profilini %60 tamamladığında her iki tarafa 25 mor elmas verilir. Kullanıcı başına max 10 ödüllü davet hakkı.

## Kararlar

| Karar | Seçim |
|-------|-------|
| Ödül yapısı | Çift taraflı (25/25 mor elmas) |
| Tetikleme koşulu | Kayıt + profil %60 tamamlama |
| Davet limiti | 10 kişi (max 250 mor elmas) |
| Kod/link | Hem 8 haneli kod hem deep link |
| UI yerleşimi | Elmas ekranında ana CTA + profilde hatırlatıcı banner |
| Teknik yaklaşım | Basit referral tablosu (Yaklaşım A) |

## Veritabanı

### `users` tablosuna eklenen kolon:
- `referral_code` (VARCHAR 8, UNIQUE, NOT NULL) — kayıt sırasında auto-generate
- Karakter seti: büyük harf + rakam (I/O/0/1 hariç)

### Yeni `referrals` tablosu:

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| id | UUID PK | — |
| referrer_id | UUID FK → users | Davet eden |
| referee_id | UUID FK → users | Davet edilen |
| status | ENUM('pending', 'completed') | Profil %60 olunca completed |
| referrer_rewarded | BOOLEAN DEFAULT false | Davet edenin ödülü verildi mi |
| referee_rewarded | BOOLEAN DEFAULT false | Davet edilenin ödülü verildi mi |
| created_at | TIMESTAMPTZ | Kayıt anı |
| completed_at | TIMESTAMPTZ | %60 profil tamamlama anı |

### Kısıtlamalar:
- UNIQUE(referee_id) — bir kişi sadece bir kez davet edilmiş olabilir
- UNIQUE(referrer_id, referee_id) — aynı çift tekrar olamaz
- referrer_id ≠ referee_id — kendi kendini davet edemez

## Backend API

### Yeni Routes: `/api/v1/referrals`

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/my-code` | Kullanıcının kendi referral kodunu döner |
| GET | `/stats` | Davet istatistikleri (toplam, pending, completed, kalan hak) |
| GET | `/history` | Davet edilen kişilerin listesi (isim, durum, tarih) |
| POST | `/validate-code` | Kayıt sırasında kodun geçerli olup olmadığını kontrol |

### Kayıt akışı değişikliği:
- `POST /auth/register` → opsiyonel `referral_code` parametresi
- Kod geçerliyse `referrals` tablosuna `pending` kayıt oluşturulur
- Kullanıcıya otomatik `referral_code` generate edilir

### Ödül tetikleme:
- `PUT /users/me` endpoint'inde profil tamamlama %60'a ulaşınca:
  1. Status → `completed`, `completed_at` set
  2. Referrer'ın completed referral sayısı ≤ 10 kontrol
  3. Her iki tarafa `diamond.service.addPurple(25, 'referral_reward')`
  4. `referrer_rewarded` ve `referee_rewarded` → true

### Yeni Service: `referral.service.ts`
- `generateCode()` — benzersiz 8 haneli kod
- `applyReferralCode(refereeId, code)` — kayıt sırasında kodu uygular
- `checkAndReward(userId)` — profil güncellemede tetiklenir
- `getStats(userId)` — davet istatistikleri
- `getHistory(userId)` — davet geçmişi

## Flutter

### Yeni dosyalar:
- `lib/data/models/referral_model.dart` — ReferralStats, ReferralHistory, ReferralItem
- `lib/data/repositories/referral_repository.dart` — API çağrıları
- `lib/core/network/services/referral_service.dart` — network katmanı
- `lib/providers/referral_provider.dart` — ReferralNotifier

### UI:
- **Elmas ekranı**: Purchase grid üstünde "Arkadaşını Davet Et, 25 Elmas Kazan" banner + kod/paylaş butonları + "3/10 davet kullanıldı" progress
- **Profil ekranı**: Küçük hatırlatıcı kart → elmas ekranına yönlendirme
- **Kayıt akışı**: "Davet kodun var mı?" opsiyonel input
- **Deep link**: `qulo.app/invite/{code}` → uygulama açılır veya store'a yönlendirilir
- **Paylaşım**: share_plus ile native share sheet

## Güvenlik & Edge Case'ler

### Suistimal önleme:
- UNIQUE referee_id — bir kişi 1 kez davet edilebilir
- referrer_id ≠ referee_id — kendi kendini davet edemez
- Max 10 completed referral (backend hard check)
- Referral kodu değiştirilemez
- Silinen hesap reward tetiklemez

### Edge case'ler:
- Geçersiz kod → hata mesajı, kayıt devam eder
- Referrer 10 limite ulaşmış → referee ödül alır, referrer almaz
- Profil %60 üstünde olup düşürülürse → ilk tetikleme yeterli, geri alınmaz
- Aynı cihazdan çoklu hesap → v1 için kabul edilebilir risk
