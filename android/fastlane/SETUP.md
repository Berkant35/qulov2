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

**Google Play service account — KURULDU** (2026-08-01):

- GCP projesi: `qulo-b2f1a` (uygulamanin Firebase projesi)
- Service account: `qulo-play-publisher@qulo-b2f1a.iam.gserviceaccount.com`
- Anahtar: `~/private_keys/qulo-play-service-account.json` (izin `600`)
- Play yetkisi **sadece Qulo uygulamasina** verildi (hesap geneli DEGIL):
  uygulama bilgisi (salt okunur) · uretim surumune yayinlama · test kanallarina
  yayinlama · magazadaki varligi yonetme.
  **Verilmedi:** yonetici, finansal veri, siparis/abonelik yonetimi.

> Play Console'da artik "API erisimi" sayfasi YOK (Ayarlar altinda arama, bulamazsin).
> Guncel akis: GCP'de service account olustur → Play Console → Kullanicilar ve
> izinler → **Yeni kullanicilar davet et** → SA e-postasini gir → uygulama bazli
> izinleri sec.

Dogrula:

```bash
cd android
fastlane run validate_play_store_json_key json_key:$HOME/private_keys/qulo-play-service-account.json
# beklenen: "Successfully established connection to Google Play Store."
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
node scripts/sync_play_changelogs.mjs 69     # elle versionCode
```

**Hedef diller sabit DEGIL** — script Play Developer API'sinden magaza listelemesi
dillerini canli ceker. Sebep: sabit liste ilk denemede patladi
(`Invalid request - This app has no title for language fr-FR`). Play, magaza
listelemesi olmayan dile release notu kabul etmiyor.

Su an Play'de **10 dil** var: `ar de-DE en-AU en-CA en-GB en-IN en-SG en-US en-ZA tr-TR`.
16 dilin kalani (fr, es, it, pt, nl, pl, ru, sv, hi, ja, ko, zh) Play'de magaza
listelemesi olmadigi icin atlanir; Ingilizce varyantlari (`en-*`) `en` metnini alir.
Play'e dil eklenir/cikarilirsa script kendini duzeltir.

Script Play'in **500 karakter/dil** sinirini de kontrol eder; asilirsa dosya
yazmadan hata verir.

## Dikkat

- `production_draft` bilerek **taslak** birakiyor — yayina alma karari insanda kalsin.
- `skip_upload_images/screenshots` acik: bu lane'ler store gorsellerine dokunmaz,
  yanlislikla ekran goruntusu silinmesin diye.
- Once `sync_changelogs`, sonra build: changelog dosyasi versionCode bazli; eski
  koda yazilirsa Play yeni surumde notu bos gosterir.
- `Appfile` paket adi `com.wordpress.calikusuberkant.qulo` (iOS bundle id'den
  FARKLI — iOS'ta `...qulorelease`).
