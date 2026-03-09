# Map Picker Ekranı Yeniden Tasarımı

## Tarih: 2026-03-09

## Sorunlar
1. Harita yüklenirken beyaz/boş ekran görünüyor
2. Şehir algılanırken garip loading spinner çıkıyor
3. "Buraya Taşın — 50 💎" yazıyor ama pasaport artık ücretsiz olacak
4. Sağ alttaki konum butonu görünmüyor (z-index sorunu)
5. Harita varsayılan Google Maps stili — markasız
6. Pin çok standart (Material Icons.location_on)

## Çözüm Tasarımı

### 1. Custom Harita Stili
- Light mode: Minimal açık tema — POI/transit kaldırılmış, mor vurgulu su/park
- Dark mode: Koyu tema — koyu gri zemin, açık gri yollar, mor vurgulu su/park
- JSON style dosyaları: `assets/map/map_style_light.json`, `assets/map/map_style_dark.json`
- Tema değişiminde otomatik uygulanacak (ThemeMode'a göre)

### 2. Custom Q Pin
- Klasik damla şeklinde pin, ortasında "Q" logosu
- Mor gradient (AppColors.primary → AppColors.primaryDark)
- CustomPainter ile çizilecek — asset bağımlılığı yok
- Hafif gölge efekti

### 3. Loading Düzeltmeleri
- Harita yüklenme: onMapCreated'a kadar Qulo temalı arka plan + AppLoadingWidget, sonra fade-in
- Şehir algılama: Spinner yerine mevcut şehir adı kalacak, opacity animasyonu ile "güncelleniyor" hissi

### 4. Ücretsiz Pasaport
- Buton metni: "Buraya Taşın" (elmas maliyeti kaldırılacak)
- Backend'de maliyet kontrolü 0 yapılacak veya kaldırılacak

### 5. Konum Butonu Düzeltmesi
- Stack'te bottom panel'in üstünde yer alacak (z-index)
- Boyut: 48px, elevation/gölge eklenecek
- Pozisyon: bottom panel üstünde, sağ kenarda

## Etkilenen Dosyalar
- `lib/features/passport/screens/map_picker_screen.dart` (ana değişiklikler)
- `lib/core/constants/app_constants.dart` (passportCostPurple kaldırma/0 yapma)
- `lib/core/l10n/app_localizations.dart` (buton metni güncelleme)
- `assets/map/map_style_light.json` (yeni)
- `assets/map/map_style_dark.json` (yeni)
- `lib/features/passport/widgets/q_map_pin.dart` (yeni — CustomPainter)
- `lib/features/passport/screens/passport_screen.dart` (maliyet referansları)
- Backend: passport route/service (maliyet kontrolü)
