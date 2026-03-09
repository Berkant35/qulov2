# Auth Improvements Design

## Problem
- Login/register hataları kullanıcıya gösterilmiyor (sessiz hata)
- Backend error code'ları (INVALID_CREDENTIALS, EMAIL_ALREADY_EXISTS) parse edilmiyor
- Register'da yaş girişi düz TextField, date picker yok
- 18+ yaş kontrolü yok
- Privacy policy / terms of service kabul mekanizması yok
- Validator mesajları hardcoded İngilizce
- UI komponentleri theme'den beslenmiyor

## Solution

### 1. Error Message System
- DioException'dan backend error code parse edilecek (response.data['error']['code'])
- Mevcut `ApiErrorModel` aktif kullanılacak
- Custom exception class: `ApiException` (code + params taşır)
- Error code → i18n key mapping (TR + EN)
- Inline hata gösterimi: ilgili input altında kırmızı mesaj
- Token interceptor'da error parsing

### 2. Register Wizard (5 Step)
- Step 1: İsim + Soyisim
- Step 2: Doğum tarihi (date picker, 18+ zorunlu)
- Step 3: Cinsiyet (Erkek / Kadın / Diğer) — backend'e "other" eklenmeli
- Step 4: Email + Şifre
- Step 5: Privacy Policy + Terms of Service onayı → Kayıt butonu
- Linear progress bar üstte (adım ilerlemesi)
- PageView veya IndexedStack ile adımlar arası animasyonlu geçiş
- Geri butonu ile önceki adıma dönüş

### 3. Privacy Policy & Terms of Service
- WebView ile gösterim (url_launcher veya webview_flutter)
- Demo placeholder URL'ler (şimdilik statik HTML)
- Checkbox ile onay zorunlu — onaylanmadan kayıt butonu disabled

### 4. Login Screen
- Mevcut yapı korunacak
- Inline hata mesajları eklenecek (email/password alanları altında)
- Backend error code'a göre doğru mesaj gösterilecek

### 5. Shared Components (lib/core/widgets/)
- `AppTextField` — theme'den beslenen, inline error destekli, prefix/suffix icon
- `AppDatePicker` — doğum tarihi seçici, 18+ validasyon built-in
- `AppButton` — primary/secondary/text variants, loading state
- `AppProgressBar` — wizard step indicator (linear)
- `AppCheckbox` — label + link destekli (privacy policy linki için)

### 6. Theme Updates
- InputDecorationTheme: border, error style, label style
- Error color, error text style
- Button theme: primary/secondary variants
- Progress indicator theme

### 7. i18n Keys (EN + TR)
Auth error codes:
- INVALID_CREDENTIALS → "Email or password is incorrect" / "Email veya şifre hatalı"
- EMAIL_ALREADY_EXISTS → "This email is already registered" / "Bu email zaten kayıtlı"
- EMAIL_NOT_VERIFIED → "Please verify your email first" / "Lütfen önce emailinizi doğrulayın"
- VALIDATION_ERROR → "Please check your input" / "Lütfen girişlerinizi kontrol edin"
- RATE_LIMITED → "Too many attempts, try again later" / "Çok fazla deneme, daha sonra tekrar deneyin"
- SERVER_ERROR → "Something went wrong" / "Bir hata oluştu"

Register wizard labels:
- Step titles, field labels, button texts, privacy policy text

### 8. Backend Change
- Gender enum'a "other" seçeneği eklenmeli (register validation)

## Architecture

```
lib/core/
  widgets/
    app_text_field.dart
    app_date_picker.dart
    app_button.dart
    app_progress_bar.dart
    app_checkbox.dart
  error/
    api_exception.dart      (new - custom exception with code+params)
  theme/
    app_theme.dart           (update - input, button, error styles)

lib/core/network/
  token_interceptor.dart     (update - parse error codes from response)

lib/features/auth/screens/
  login_screen.dart          (update - inline errors)
  register_screen.dart       (rewrite - wizard with 5 steps)

lib/features/auth/widgets/
  register_step_*.dart       (new - each wizard step)

lib/core/l10n/
  app_localizations.dart     (update - error code + register wizard keys)
```
