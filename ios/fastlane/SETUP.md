# Qulo — iOS release (fastlane) kurulum ve kullanim

> `README.md` fastlane tarafindan **otomatik uretiliyor ve her kosuda uzerine
> yaziliyor** — kalici not buraya yazilir.

Bu klasor App Store Connect / TestFlight yuklemesini otomatiklestirir.

Onceden `deploy_testflight.sh` zincirin sadece yarisini yapiyordu: build alip
yukluyor, **release notlarina hic dokunmuyordu**. 16 dillik "What to Test" ve
App Store "Yenilikler" metinleri elle, ayri node scriptleriyle gonderiliyordu.
Android'de `fastlane android ship_internal` tek komutla yaparken iOS'ta
yapmiyordu — bu klasor o farki kapatiyor.

`deploy_testflight.sh` **duruyor ve calisiyor**; fastlane onun yerine gecmiyor,
uzerine release notu adimlarini ekliyor.

## Kurulum (tek seferlik)

```bash
brew install fastlane
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8   # fastlane UTF-8 locale ister
```

**App Store Connect API anahtari — KURULU:**

- Key ID: `B24C75LYRD` (`.env` icinde `APP_STORE_API_KEY`)
- Issuer ID: `.env` icinde `APP_STORE_API_ISSUER`
- Anahtar dosyasi: `~/.private_keys/AuthKey_B24C75LYRD.p8`

> **Dikkat — iki farkli dizin:** node scriptleri `~/.private_keys/` (noktali),
> `deploy_testflight.sh` ise `~/private_keys/` (noktasiz) okuyor. Su an ikisinde
> de var. Anahtari tasirsan iki yeri de guncelle.

## Lane'ler

| Lane | Ne yapar |
|------|----------|
| `version_info` | pubspec.yaml'dan surum + build numarasi okur |
| `preflight` | **Build almadan once** surumun App Store'da build kabul ettigini dogrular |
| `build_ipa` | `flutter build ipa --release` (prod API) |
| `beta` | IPA'yi TestFlight'a yukler, islenmesini bekler |
| `notes` | TestFlight "What to Test" — 16 dil |
| `whatsnew` | App Store "Yenilikler" — tum lokalizasyonlar |
| `ship_beta` | preflight → build_ipa → beta → notes |

```bash
cd ios
fastlane ios ship_beta      # tam akis
fastlane ios preflight      # sadece kontrol, hicbir sey degistirmez
fastlane ios whatsnew       # sadece App Store metinleri
```

## `preflight` neden var

2026-09-01'de 2.0.7+70 build'i alindi (~20 dakika), yuklendi ve Apple reddetti:

```
90186 — Invalid Pre-Release Train. The train version '2.0.7' is closed
90062 — CFBundleShortVersionString must contain a higher version than
        the previously approved version
```

2.0.7 zaten `READY_FOR_SALE` oldugu icin o surume **hicbir build** gonderilemiyordu.
Build numarasini artirmak cozmuyor; `pubspec.yaml`'daki surumu yukseltmek gerekiyordu.

`preflight` bunu build'den once, saniyeler icinde yakalar
(`scripts/asc_version_state.mjs`).

## Release notlari

Tek kaynak: `scripts/testflight_release_notes.json`.

Ayni dosyayi Android changelog'lari da kullaniyor
(`node scripts/sync_play_changelogs.mjs <versionCode>`) — iki magaza tek metin.

Dil kapsamlari **ayni degil**, bilerek:

- Uygulama: 16 dil
- App Store: 21 lokalizasyon (`cs`, `hu`, `sl-SI`, `en-AU/CA/GB`, `pt-PT` dahil;
  `pl` ve `zh` **yok**)
- Google Play: 10 magaza dili (7'si Ingilizce varyanti)

JSON'da karsiligi olmayan bir lokalizasyon Ingilizce'ye duser.

## Yapmadigi sey

`whatsnew` metinleri yazar ama **incelemeye gondermez**. Build secimi ve
"Incelemeye Gonder" adimi App Store Connect'ten elle yapilir — bu bilincli bir
tercih; yanlislikla inceleme baslatmamak icin.
