# Qulo — Android release (fastlane) kurulum ve kullanim

> `README.md` fastlane tarafindan **otomatik uretiliyor ve her kosuda uzerine
> yaziliyor** — kalici not buraya yazilir.

Bu klasor Google Play yuklemesini otomatiklestirir. Onceden AAB elle build edilip
Play Console'a elle yukleniyor, release notlari 16 dile elle yapistiriliyordu.

iOS tarafi **bu akisin disinda** — orada calisan kendi zinciri var
(`deploy_testflight.sh` + `scripts/push_testflight_notes.mjs`).

## Kurulum (tek seferlik)

```bash
brew install fastlane
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8   # fastlane UTF-8 locale ister
```

**Google Play service account** — henuz YOK, yukleme yapmadan once gerekli:

1. Play Console → Setup → API access
2. Google Cloud projesinde service account olustur
3. Play Console'da o hesaba **Release manager** yetkisi ver
4. JSON anahtarini indir → `~/private_keys/qulo-play-service-account.json`
   (ya da `PLAY_JSON_KEY_FILE` ile baska yol ver)

Dogrula:

```bash
cd android
fastlane run validate_play_store_json_key json_key:$HOME/private_keys/qulo-play-service-account.json
```

Anahtar yoksa lane'ler yuklemeye kalkismadan once net bir mesajla duruyor.

## Gunluk kullanim

```bash
cd android

fastlane android ship_internal      # notlari uret → AAB build → internal track
fastlane android production_draft   # production'a TASLAK (yayina alma Play Console'dan)
fastlane android notes_only         # sadece release notlarini guncelle
fastlane android sync_changelogs    # notlari yeniden uret (build yok)
fastlane android version_info       # pubspec'teki surumu yazdir
```

## Release notlari nereden geliyor

Tek kaynak: **`scripts/testflight_release_notes.json`** (16 dil).
Ayni dosyayi App Store ve TestFlight de kullaniyor — metni orada degistir, sonra:

```bash
node scripts/sync_play_changelogs.mjs        # versionCode pubspec.yaml'dan
node scripts/sync_play_changelogs.mjs 68     # elle versionCode
```

Bu, `metadata/android/<locale>/changelogs/<versionCode>.txt` dosyalarini uretir.
Script Play'in **500 karakter/dil** sinirini kontrol eder; asilirsa dosya yazmadan
hata verir.

## Dikkat

- `production_draft` bilerek **taslak** birakiyor — yayina alma karari insanda kalsin.
- `skip_upload_images/screenshots` acik: bu lane'ler store gorsellerine dokunmaz,
  yanlislikla ekran goruntusu silinmesin diye.
- Once `sync_changelogs`, sonra build: changelog dosyasi versionCode bazli; eski
  koda yazilirsa Play yeni surumde notu bos gosterir.
- `Appfile` paket adi `com.wordpress.calikusuberkant.qulo` (iOS bundle id'den
  FARKLI — iOS'ta `...qulorelease`).
