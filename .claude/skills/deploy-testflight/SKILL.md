---
name: deploy-testflight
description: Use when deploying Qulo iOS app to TestFlight, building IPA, uploading to App Store Connect, or incrementing build numbers
---

# Deploy to TestFlight

## Overview
Qulo iOS uygulamasini TestFlight'a deploy eder. Build number otomatik arttirilir, IPA olusturulur ve App Store Connect'e yuklenir.

## IMPORTANT: Execution Rules
- Bu skill calistirildiginda HICBIR IZIN SORULMAZ — tum adimlari otomatik ve force olarak calistir
- `.env` dosyasinda API key ve Issuer ID mevcut — script otomatik okur
- Upload basarisiz olursa Transporter ile otomatik ac, kullaniciya soru sorma

## When to Use
- Kullanici "testflight'a yukle", "deploy et", "build al" dediginde
- iOS release build gerektiginde
- TestFlight guncellemesi istendiginde

## Prerequisites
- Xcode ve Flutter SDK kurulu
- `ios/ExportOptions.plist` mevcut
- `.env` dosyasinda `APP_STORE_API_KEY` ve `APP_STORE_API_ISSUER` tanimli

## App Store Connect Credentials
- **API Key ID:** B24C75LYRD
- **Issuer ID:** .env dosyasindan okunur
- **Key file:** ~/private_keys/AuthKey_B24C75LYRD.p8
- Script `.env` dosyasini otomatik yukler, ayrica export'a gerek yok

## Steps

### 1. Tek komutla deploy
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
chmod +x deploy_testflight.sh
./deploy_testflight.sh
```

Script sunlari yapar:
1. `.env` dosyasini yukler (API key + Issuer ID)
2. `pubspec.yaml`'da build number +1 arttirir
3. `flutter clean && flutter pub get`
4. `flutter build ipa --release` ile IPA olusturur
5. `xcrun altool` ile TestFlight'a yukler

### 2. API URL degistirme
```bash
API_BASE_URL="https://custom-api.example.com/api/v1" ./deploy_testflight.sh
```
Default: `https://qulo-server-production.up.railway.app/api/v1`

### 3. Upload basarisiz olursa
Transporter.app ile `build/ios/ipa/*.ipa` dosyasini suruklep birak

## Common Mistakes
- ExportOptions.plist eksikse build basarisiz olur — `ios/ExportOptions.plist` kontrol et
- Signing hatasi: Xcode'da provisioning profile ve certificate kontrol et
- Build number cakismasi: App Store Connect'te ayni build number varsa reject eder — script otomatik arttirir
