# Profil On Izleme + Kaydetme Basari Feedback'i

**Tarih:** 2026-03-22
**Durum:** Onaylandi

## Ozet

Kullanicinin kendi profilini baskasinin gozunden on izlemesi ve profil kaydettikten sonra basari feedback'i almasi.

## Erisim Noktalari

### A — Edit Profile Ekrani
- AppBar sag ustunde goz ikonu butonu
- Tiklayinca `ProfilePreviewScreen` acilir

### B — Profil Ana Ekrani
- `ProfileIdentityCard` tiklanabilir olur
- Dokunuldigunda `ProfilePreviewScreen` acilir
- Gorsel ipucu: kartin sag altina kucuk goz ikonu

## Profil On Izleme Ekrani

`ProfileDetailScreen`'in birebir aynisi, su farklarla:

- **Action bar yok** (coz/reddet/mesaj butonlari kaldirilir)
- **Mesafe ve online durumu gizli** (kendi profilinde anlamsiz)
- **Alt buton**: "Profili Duzenle" — tiklayinca `EditProfileScreen`'e gider
- **Veri kaynagi**: Mevcut `userProvider`'dan (API cagrisi yok, bellekte mevcut veri)

### Gosterilen Bilgiler
- Fotograf galerisi (carousel)
- Isim, yas, sehir
- Iliski hedefi (relationship goal chip)
- Bio
- Detaylar grid (burc, is, okul, sigara, alkol, evcil hayvan, muzik, kisilik)
- Soru bilgisi (kac soru var — userProvider'daki `questionCount` kullanilir)

### Gosterilmeyen Bilgiler
- Mesafe (kendi profilinde anlamsiz) — `ProfileBasicInfo`'ya `showDistance` parametresi eklenir
- Online durumu (kendi profilinde anlamsiz) — mevcut `showOnlineStatus: false` kullanilir
- Action bar (coz/reddet/mesaj — kendi profiline anlamsiz)
- Report butonu (kendini raporlamak anlamsiz)

## Kaydetme Basari Feedback'i

Profil basariyla kaydedildikten sonra bottom sheet acilir:

### Bottom Sheet Icerigi
- Checkmark ikonu (animasyonlu veya statik)
- "Profilin basariyla guncellendi" mesaji
- "On Izle" butonu — tiklayinca on izleme ekranina gider
- Sheet kapatilabilir (disina tiklama veya asagi cekme)

### Milestone Siralama
Eger profil tamamlama milestone'u varsa:
1. Once `MilestoneCelebrationSheet` gosterilir
2. Kapaninca success bottom sheet gosterilir

Milestone yoksa direkt success bottom sheet acilir.

## Teknik Yaklasim

### Yeni Dosyalar
- `lib/features/profile/screens/profile_preview_screen.dart` — on izleme ekrani
- `lib/features/profile/mixins/profile_preview_screen_mixin.dart` — ekran logic'i
- `lib/features/profile/widgets/profile_save_success_sheet.dart` — basari bottom sheet

### Neden Ayri Ekran (`ProfilePreviewScreen`)
`ProfileDetailScreen`'e `isPreview` parametresi eklemek yerine ayri ekran olusturulur cunku:
- Veri kaynagi farkli: baskasinin profili API'den, kendi profilin `userProvider`'dan
- Action bar tamamen farkli (duzenle vs coz/reddet/mesaj)
- Single Responsibility — on izleme kendi ekrani olarak daha temiz

### Widget Reuse
Mevcut `profile_detail/widgets/` altindaki widget'lar reuse edilir:
- `ProfilePhotoGallery` — fotograf carousel
- `ProfileBasicInfo` — isim, yas, sehir (showOnlineStatus: false, showDistance: false)
  - **Gerekli degisiklik:** `ProfileBasicInfo`'ya `showDistance` parametresi eklenir (default: true)
- `ProfileBioSection` — bio metni
- `ProfileDetailsGrid` — detaylar grid
- `ProfileQuestionInfo` — soru bilgisi

**Not:** `ProfileReportButton` on izleme ekraninda kullanilmaz (kendini raporlamak anlamsiz).

### Data Mapping
`UserModel` + `UserDetailsModel` → `PublicProfileModel` donusumu icin mapper metodu:
- `UserModel.toPublicProfile()` extension veya helper method
- `distanceKm`: null (gosterilmeyecek)
- `isOnline`: false (gosterilmeyecek)
- `questionInfo`: `UserModel.questionCount`'tan turetilir (sadece toplam soru sayisi, cozulme orani on izlemede gosterilmez — kendi sorularinizi baskasi cozmeden oran anlamsiz)

### Loading/Error State
- `userProvider` bellekte oldugu icin loading nadir ama AsyncValue oldugundan:
  - Loading: `AppScaffold(isLoading: true)` gosterilir
  - Error: snackbar gosterilir, pop back yapilir

### Routing
- Route: `/profile/preview` (GoRouter)
- `NavigationService` uzerinden navigate edilir

### Degisiklikler Mevcut Dosyalarda
- `edit_profile_screen.dart` — AppBar'a goz ikonu eklenir
- `edit_profile_screen_mixin.dart` — save() basari sonrasi success sheet gosterilir, on izleme navigasyonu eklenir
- `profile_identity_card.dart` — GestureDetector/InkWell sarmalayicisi, goz ikonu eklenir
- `profile_screen.dart` — kart tiklama callback'i eklenir
- Routing dosyasi — `/profile/preview` route'u eklenir

### Analytics Event'leri
- `profile_preview_opened` — on izleme acildi (source: "edit_screen" | "profile_screen")
- `profile_preview_edit_tapped` — on izlemeden "Profili Duzenle" butonuna basildi
- `save_success_preview_tapped` — basari sheet'inden "On Izle" butonuna basildi

### i18n Key'leri
- `profile_preview` — AppBar basligi
- `profile_preview_tooltip` — goz ikonu accessibility label
- `edit_profile` — alt buton metni (mevcut)
- `profile_updated_success` — "Profilin basariyla guncellendi"
- `preview_profile` — "On Izle" buton metni

### Dosya Konumu Karari
`ProfilePreviewScreen` `lib/features/profile/` altina konur (ayri `profile_preview/` feature modulu degil) cunku:
- Veri kaynagi ve navigasyon `profile` feature'ina ait
- Ekran basit — sadece widget reuse + mapper, kendi provider'i yok
- `profile_detail/` baskasinin profiline ozel kalmali
