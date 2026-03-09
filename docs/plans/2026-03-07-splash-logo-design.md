# Splash & Logo Design

## Goal
Native splash + animated Flutter splash + login ekranına logo entegrasyonu.

## Decisions

### Native Splash
- Arka plan: Mor (#9C27B0 / AppColors.purple)
- Logo: quloSplash.svg'den dönüştürülmüş beyaz PNG
- flutter_native_splash config pubspec.yaml'da
- Cold start boşluğunu kapatır

### Flutter Animated Splash
- Arka plan: Mor (AppColors.purple)
- Animasyon (~2sn):
  1. Logo fade-in + scale (0.7 -> 1.0) — 1sn
  2. "Qulo" text fade-in — 0.5sn offset, 0.5sn süre
- Logo ve text beyaz
- Animasyon sonrası fade-out (~500ms) ile login/home'a geçiş
- Route: /splash, uygulama açılışında ilk ekran
- Auth durumuna göre login veya home'a yönlendir

### Login Ekranı
- Text-only "Qulo" başlığı kaldırılır
- Yerine: SVG logo (~80px) + "Qulo" text + "Tekrar hoş geldin"
- Form alanları aynen kalır

## Files
- `lib/features/splash/splash_screen.dart` — Animated splash
- `assets/splash/` — Native splash PNG
- `pubspec.yaml` — flutter_native_splash config
- `lib/features/auth/screens/login_screen.dart` — Logo ekleme
