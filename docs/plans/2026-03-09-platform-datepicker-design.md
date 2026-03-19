# Platform Bazli DatePicker Tasarimi

## Ozet
`AppDatePicker` widget'ini platform-adaptive hale getirme. iOS'ta CupertinoDatePicker (bottom sheet, wheel picker), Android'de mevcut Material showDatePicker. Locale-aware tarih formatlama.

## Mevcut Durum
- `lib/core/widgets/app_date_picker.dart` — her platformda Material `showDatePicker` kullaniyor
- 18-100 yas kisitlamasi mevcut
- Tarih formati hardcoded DD/MM/YYYY
- Tek kullanim yeri: `register_step_birthday.dart`

## Tasarim Kararlari

### Android
- Mevcut Material `showDatePicker` dialog'u aynen korunur
- `DatePickerMode.year` ile baslar, mor temali header

### iOS
- Bottom sheet ile `CupertinoDatePicker` (wheel picker)
- Sade gorunum: ustte baslik + "Tamam" butonu, altta wheel
- Arka plan app temasina uygun (koyu tema)
- `CupertinoDatePicker.dateOrder` locale'e gore otomatik

### Locale-Aware Formatlama (Her iki platform)
- `intl` paketi ile `DateFormat.yMd(locale)` kullanimi
- TR: `09.03.2000`, ay isimleri Turkce
- EN: `3/9/2000`, ay isimleri Ingilizce
- CupertinoDatePicker locale parametresi ile wheel'da dogru ay isimleri

### Platform Ayirimi
- `dart:io` `Platform.isIOS` ile kontrol
- Tek dosyada (`app_date_picker.dart`) her iki platform icin logic

## Degisecek Dosyalar
- `lib/core/widgets/app_date_picker.dart` — platform kontrolu, iOS bottom sheet, locale-aware format

## Kisitlamalar
- Min yas: 18, Max yas: 100 (mevcut, korunur)
- Harici paket eklenmez (`intl` zaten mevcut)
