# Referral Code Post-Login Redesign

## Problem

Mevcut sistemde referral kodu sadece kayit (register) sirasinda girilebiliyor. Kayit sonrasi kullanici davet kodunu giremez. Bu kisitlama:
- Kayit aninda kodu bilmeyen kullanicilari disliyor
- Deep link'ten gelen kullanicilar icin gereksiz friction yaratiyordu
- Kayit akisina fazladan karmasiklik ekliyordu

## Karar

Referral kodu girisi register akisindan kaldirilir. Kullanici login sonrasi Diamonds ekranindaki mevcut referral kartindan **bir kez** kod girebilir. Her kullanici yalnizca bir kisi tarafindan davet edilebilir (mevcut DB constraint korunur).

## Tasarim

### 1. Register Akisindan Kaldirma

**Kaldirilan prop'lar (`RegisterStepTerms`):**
- referralCodeCtrl, referralExpanded, onToggleReferral, onValidateReferral
- validatingReferral, referralValidName, referralError

**Kaldirilan state/logic (`RegisterScreenMixin`):**
- referralCodeCtrl, referralExpanded, validatingReferral, referralValidName, referralError
- `validateReferralCode()` metodu
- `register()` metodundan `referralCode` parametresi

**Kaldirilan parametreler:**
- `AuthNotifier.register()` -> referralCode
- `AuthRepository.register()` -> referralCode
- `auth_repository.dart` -> request body'den `referral_code`

### 2. Backend: Yeni Endpoint'ler

#### POST /referrals/apply
- **Auth:** Gerekli (Bearer token)
- **Body:** `{ "code": "ABC2D3EF" }` (string, 1-10 char, uppercase'e cevirilir)
- **Basari (200):** `{ "referrerName": "Ali" }`
- **Hatalar:**
  - 404 INVALID_REFERRAL_CODE: Kod bulunamadi
  - 400 SELF_REFERRAL: Kendi kodunu giremez
  - 409 ALREADY_REFERRED: Zaten bir davet kodu kullanmis
- **Mantik:** Mevcut `applyReferralCode(userId, code)` servisini kullanir

#### GET /referrals/my-referrer
- **Auth:** Gerekli (Bearer token)
- **Basari (200):** `{ "referrerName": "Ali", "status": "pending" | "completed" }` veya `{ "referrerName": null }`
- **Mantik:** `referrals` tablosunda `referee_id = userId` olan satirin referrer adini ve durumunu doner

### 3. Flutter: Referral State Genisletme

**ReferralState'e eklenen alanlar:**
```dart
String? referredBy;    // Davet eden kisinin adi (null = henuz kod girilmemis)
String? referralStatus; // "pending" | "completed" (null = yok)
```

**Getter:**
```dart
bool get hasAppliedCode => referredBy != null;
```

**ReferralNotifier degisiklikleri:**
- `fetchAll()` -> ek olarak `getMyReferrer()` cagirir, `referredBy` ve `referralStatus` doldurur
- `applyCode(String code)` -> Yeni metod, `POST /referrals/apply` cagirir, basari sonrasi state gunceller

**Yeni service metodlari (`ReferralService`):**
```dart
@POST('/referrals/apply')
Future<dynamic> applyCode(@Body() Map<String, dynamic> data);

@GET('/referrals/my-referrer')
Future<dynamic> getMyReferrer();
```

**Yeni repository metodlari (`ReferralRepository`):**
```dart
Future<Result<String>> applyCode(String code);       // referrerName doner
Future<Result<MyReferrerResponse>> getMyReferrer();   // referrer bilgisi
```

**Yeni model (`referral_model.dart`):**
```dart
class MyReferrerResponse {
  final String? referrerName;
  final String? status; // "pending" | "completed"
}
```

### 4. UI: ReferralInviteCard Degisikligi

Mevcut `_FullCard` widget'inin alt kismina yeni bolum eklenir. Iki durum:

#### Durum A: Kod girilmemis (`referredBy == null`)
- Ayirici cizgi
- Text input (AppTextField, hint: "Davet kodunu gir", prefix: gift icon)
- "Uygula" butonu (FilledButton)
- Validate sonucu: yesil mesaj (gecerli + isim) veya kirmizi hata
- Loading state: buton yerine spinner

#### Durum B: Kod girilmis (`referredBy != null`)
- Ayirici cizgi
- Mini bilgi karti: check icon + "{referredBy} tarafindan davet edildin"
- Odul durumu:
  - `status == "pending"`: "Profilini %60 tamamla, odul kazan" (amber renk)
  - `status == "completed"`: "25 mor elmas kazandin" (yesil renk, elmas ikonu)

**Widget parametreleri eklenir:**
```dart
// ReferralInviteCard'a eklenen prop'lar
final String? referredBy;
final String? referralStatus;
final ValueChanged<String>? onApplyCode;
final bool applyingCode;
final String? applyError;
final String? applySuccessName;
```

**DiamondsReferralSection** bu yeni prop'lari referralProvider'dan okuyarak baglayacak.

### 5. Deep Link Akisi

#### Mevcut (kaldirilacak):
```
/invite/CODE -> /auth/login/register?referralCode=CODE
```

#### Yeni:
```
/invite/CODE -> Kullanici auth degil mi?
  Evet -> /auth/login + pendingReferralCode=CODE (SharedPreferences)
  Hayir -> /profile/diamonds?referralCode=CODE
```

**Degisiklikler:**

1. `app_routes.dart` -> `/invite/:code` redirect mantigi guncellenir
2. `app_router.dart` -> Auth redirect'te pendingReferralCode kontrolu eklenir
3. `DiamondsScreen` -> Query param'dan `referralCode` okunur, input'a pre-fill edilir
4. `SharedPreferences` key: `pending_referral_code` (login sonrasi kontrol edilip temizlenir)

**Akis detayi (auth'suz kullanici):**
1. `/invite/CODE` tiklandi
2. Router: auth yok -> `pending_referral_code=CODE` SharedPreferences'a yaz -> `/auth/login`'e yonlendir
3. Kullanici login/register yapar
4. Auth redirect: `pending_referral_code` var mi kontrol et -> varsa `/profile/diamonds?referralCode=CODE` yonlendir + SharedPreferences temizle
5. DiamondsScreen acilir, referral input'a kod pre-fill edilir
6. Kullanici "Uygula" butonuna basar

**Akis detayi (auth'lu kullanici):**
1. `/invite/CODE` tiklandi
2. Router: auth var -> `/profile/diamonds?referralCode=CODE`'a yonlendir
3. DiamondsScreen acilir, referral input'a kod pre-fill edilir

### 6. Etkilenen Dosyalar

| Dosya | Degisiklik |
|-------|-----------|
| `register_step_terms.dart` | Referral prop'lari kaldir |
| `register_screen_mixin.dart` | Referral state/logic kaldir |
| `auth_provider.dart` | referralCode parametresi kaldir |
| `auth_repository.dart` | referralCode parametresi kaldir |
| `referral_service.dart` | `applyCode()`, `getMyReferrer()` ekle |
| `referral_service.g.dart` | build_runner ile yeniden uret |
| `referral_repository.dart` | `applyCode()`, `getMyReferrer()` ekle |
| `referral_provider.dart` | State genislet, `applyCode()` + `fetchAll` guncelle |
| `referral_model.dart` | `MyReferrerResponse` model ekle |
| `referral_model.g.dart` | build_runner ile yeniden uret |
| `referral_invite_card.dart` | Code input + referred-by bolumu ekle |
| `diamonds_referral_section.dart` | Yeni state'leri bagla |
| `app_routes.dart` | Invite redirect guncelle |
| `app_router.dart` | Pending referral code logic |
| `diamonds_screen.dart` | referralCode query param okuma |
| **Server:** `referral.routes.ts` | `POST /apply`, `GET /my-referrer` |
| **Server:** `referral.service.ts` | `getMyReferrer()` metodu |
| **Server:** `referral.validator.ts` | `applyCodeSchema` ekle |

### 7. Edge Case'ler

- **Kullanici kendi kodunu girerse:** Backend 400 SELF_REFERRAL doner, UI kirmizi hata gosterir
- **Gecersiz kod:** Backend 404 doner, UI "Gecersiz davet kodu" gosterir
- **Zaten kod girilmis:** Backend 409 doner, UI "Zaten bir davet kodu kullandin" gosterir (normalde bu durumda input gorunmez, ama race condition icin)
- **Deep link + zaten kod girilmis:** Diamonds ekrani acilir, input gorunmez, mevcut "davet edildin" karti gorunur
- **Network hatasi:** Genel hata mesaji, tekrar dene imkani
- **Profil %60 tamamlanmadan odullenme:** Backend otomatik handle ediyor (mevcut `checkAndReward` mantigi profil guncelleme sirasinda calisir)
