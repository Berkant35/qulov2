---
name: deploy-testflight
description: Use when deploying Qulo iOS app to TestFlight, building IPA, uploading to App Store Connect, or incrementing build numbers
---

# Deploy to TestFlight

## Overview
Qulo iOS uygulamasini TestFlight'a deploy eder. Build number otomatik arttirilir, IPA olusturulur ve App Store Connect'e yuklenir.

## When to Use
- Kullanici "testflight'a yukle", "deploy et", "build al" dediginde
- iOS release build gerektiginde
- TestFlight guncellemesi istendiginde

## Prerequisites
- Xcode ve Flutter SDK kurulu
- `ios/ExportOptions.plist` mevcut
- App Store Connect API key ayarli (opsiyonel, manuel upload da mumkun)

## Quick Reference

| Adim | Komut |
|------|-------|
| Tam deploy | `./deploy_testflight.sh` |
| Sadece build | `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist` |
| Manuel upload | Transporter.app ile `build/ios/ipa/*.ipa` yukle |

## Steps

### 1. Script ile otomatik deploy
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
chmod +x deploy_testflight.sh
./deploy_testflight.sh
```

Script sunlari yapar:
1. `pubspec.yaml`'da build number +1 arttirir
2. `flutter clean && flutter pub get`
3. `flutter build ipa --release` ile IPA olusturur
4. `xcrun altool` ile TestFlight'a yukler

### 2. API URL degistirme
```bash
API_BASE_URL="https://custom-api.example.com/api/v1" ./deploy_testflight.sh
```
Default: `https://api.qulo.app/api/v1`

### 3. App Store Connect API key ayarlama
```bash
export APP_STORE_API_KEY="YOUR_KEY"
export APP_STORE_API_ISSUER="YOUR_ISSUER"
./deploy_testflight.sh
```
Key yoksa script uyari verir, IPA'yi manuel yukleyebilirsin.

### 4. Manuel upload (altool basarisiz olursa)
- Transporter.app ac, `build/ios/ipa/*.ipa` dosyasini suruklep birak
- Veya: `xcrun altool --upload-app --type ios --file "build/ios/ipa/Runner.ipa" --apiKey KEY --apiIssuer ISSUER`

## Common Mistakes
- ExportOptions.plist eksikse build basarisiz olur — `ios/ExportOptions.plist` kontrol et
- Signing hatasi: Xcode'da provisioning profile ve certificate kontrol et
- Build number cakismasi: App Store Connect'te ayni build number varsa reject eder — script otomatik arttirir
