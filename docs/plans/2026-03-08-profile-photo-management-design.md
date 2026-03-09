# Profil & Fotograf Yonetimi - Tasarim Dokumani

**Tarih:** 2026-03-08
**Durum:** Onaylandi
**Branch:** APP-1915

---

## 1. Genel Bakis

Profil ekranini sifirdan yeniden tasarliyoruz. Mevcut ekranda sadece goruntulem vardi, stat kartlari (likes, views, diamonds) vardi. Yeni tasarimda:
- Stat kartlari kaldirildi (likes/views kullaniciya gosterilmeyecek)
- Tinder tarzi 3x2 fotograf grid eklendi
- Gamification rozet sistemi eklendi (Bronze/Silver/Gold + gercek elmas odulu)
- Ayri Edit Profile ekrani (tek sayfa, tum alanlar)
- Profil tamamlama motivasyonu: aksiyon ipuclari + rozet progress

## 2. Profil Ekrani Layout (profile_screen.dart)

Yukaridan asagiya:

### 2.1 AppBar
- Baslik: "Profil"
- Sag: Ayarlar ikonu (mevcut, degismez)

### 2.2 Fotograf Grid (Tinder 3x2)
- 6 slot, ilk slot buyuk (2 sutun genislik x 2 satir yukseklik)
- Diger 4 slot kucuk kare (sag tarafta 2 + alt satirda 2)
- Dolu slot: Fotograf gosterir
- Bos slot: Noktali cerceve + icImagePlus ikonu
- Sadece goruntuleme (edit modda degil)
- Tiklama: Edit Profile ekranina yonlendir

### 2.3 Isim, Yas, Sehir
- Format: "Berkant, 29 . Istanbul"
- Sehir yoksa sadece isim ve yas

### 2.4 Rozet Bari
- Mevcut seviye rozeti ikonu (icBadgeBronze/Silver/Gold) + seviye adi
- Ince progress bar (profile_completion / 100)
- Aksiyon ipucu: "Bio ekle > Silver seviyeye ulas!" gibi kisisellestirilmis mesaj
- Rozet renkleri: Bronze=#CD7F32, Silver=#C0C0C0, Gold=#FFD700

### 2.5 Hakkimda Karti
- Bio text gosterimi
- Bos ise: "Bio ekle > gorunurlugun artar" placeholder
- Tiklaninca Edit Profile'a yonlendir

### 2.6 Detaylar Karti
- Chip'ler halinde dolu alanlar: Boy, Meslek, Okul, Burc, Sigara, Alkol, Evcil Hayvan, Muzik Turu, Kisilik
- Her chip'in kendi ikonu var (icHeight, icJob, icSchool, icZodiac, icSmoke, icUseAlcohol, icPets, icMusic, icPersonality)
- Bos alanlar: Soluk "Ekle" chip'i
- Tiklaninca Edit Profile'a yonlendir

### 2.7 Tercihler Karti
- Cinsiyet tercihi, yas araligi, mesafe
- Tiklaninca Edit Profile'a yonlendir

### 2.8 Menu Ogeleri
- Sorularim (icHelpCircle)
- Elmaslarim (DiamondIcon)
- Pasaport (icPlane)

## 3. Edit Profile Ekrani (edit_profile_screen.dart)

Tek sayfa, scroll ile bolumler. Yeni route: /profile/edit

### 3.1 Fotograf Grid (Duzenleme Modu)
- Ayni 3x2 grid, ama interaktif
- Bos slot'a tikla > galeri/kamera secimi (bottom sheet) > upload
- Dolu slot'a tikla > secenekler: "Ana fotograf yap" / "Sil" (bottom sheet)
- Silme: ConfirmDialog ile onayla, sonra DELETE /users/me/photos/:index
- Ana fotograf yapma: Backend'de siralama degisikligi (ilk slot'a tasi)
- Max 6 fotograf, min 0 (zorunlu degil ama rozet icin tesvik)
- Upload: POST /users/me/photos (multer, max 5MB, jpg/png)

### 3.2 Hakkimda
- Bio TextArea (max 300 karakter)
- Karakter sayaci gosterilir
- PATCH /users/me { bio: "..." }

### 3.3 Temel Bilgiler
- Isim (TextInput, readonly — register'da alindi)
- Sehir (TextInput)
- Konum guncelle butonu: GPS'ten al, PATCH /users/me/location
- PATCH /users/me { city: "..." }

### 3.4 Detaylar
- Boy: Number picker (140-220 cm)
- Kilo: Number picker (40-200 kg)
- Burc: Dropdown (12 burc)
- Meslek: TextInput
- Okul: TextInput
- Sigara: Toggle (YES/NO/SOMETIMES)
- Alkol: Toggle (YES/NO/SOMETIMES)
- Evcil Hayvan: TextInput
- Muzik Turu: TextInput
- Kisilik: TextInput
- PATCH /users/me/details { height, weight, zodiac, ... }

### 3.5 Tercihler
- Cinsiyet tercihi: SegmentedButton (MAN/WOMAN/BOTH)
- Yas araligi: RangeSlider (18-99)
- Mesafe: Slider (1-500 km)
- PATCH /users/me { gender_pref, age_pref_min, age_pref_max, match_radius_km }

### 3.6 Kaydet
- Altta sticky buton
- Degisiklikleri toplu gonderir (profile + details + preferences ayri API call'lari)
- Basarili: Snackbar + profil ekranina don + fetchMe() tetikle

## 4. Rozet Sistemi

### 4.1 Seviyeler

| Seviye | Esik | Rozet Adi | Odul |
|--------|------|-----------|------|
| Yok | %0-29 | — | Discover'da gorunmezsin (uyari goster) |
| Bronze | %30-59 | "Caylak" | Discover'da gorunmeye baslarsin |
| Silver | %60-84 | "Populer" | 3 mor elmas hediye |
| Gold | %85-100 | "Profil Ustasi" | 10 mor elmas hediye |

### 4.2 Client-Side Hesaplama
- profile_completion backend'den geliyor (recalculateProfileCompletion)
- Rozet seviyesi Flutter'da hesaplanir (basit esik kontrolu)
- Aksiyon ipucu: Eksik alanlari analiz et, en etkili oneriyi goster

### 4.3 Backend Degisiklikleri
- Yeni kolon: users tablosuna `badge_rewards_claimed TEXT[] DEFAULT '{}'`
- Yeni endpoint: `POST /users/me/claim-badge-reward`
  - Body: { level: "SILVER" | "GOLD" }
  - Kontrol: profile_completion >= esik VE bu seviye daha once claim edilmemis
  - Basarili: mor elmas ekle + badge_rewards_claimed array'ine level ekle
  - Response: { diamonds_awarded: 3, badge_rewards_claimed: ["SILVER"] }

### 4.4 Aksiyon Ipuclari
Client-side mantik:
- photos.length < 3 > "3 fotograf ekle > gorunurlugun %20 artar!"
- bio == null > "Bio ekle > daha fazla eslesme!"
- details.job == null > "Meslegini ekle > profilini tamamla!"
- Oncelik: foto > bio > detaylar (en etkili olandan basla)

## 5. Yeni SVG Ikonlar

Olusturulacak ikonlar (assets/icons/ + QIcons'a ekle):
- `ic_height.svg` — boy (cetvel ikonu)
- `ic_weight.svg` — kilo (tartı ikonu)
- `ic_personality.svg` — kisilik (beyin/puzzle ikonu)
- `ic_badge_bronze.svg` — bronze rozet
- `ic_badge_silver.svg` — silver rozet
- `ic_badge_gold.svg` — gold rozet
- `ic_image_plus.svg` — fotograf ekleme (kare + plus)
- `ic_reorder.svg` — siralama (grip lines)
- `ic_age_range.svg` — yas araligi (iki kisi arasi ok)
- `ic_gender_pref.svg` — cinsiyet tercihi

## 6. Fotograf Siralama (Reorder) Mantigi

Backend'de photos TEXT[] array'i sirayi belirler. photos[0] = ana fotograf.

Ana fotograf degistirme:
1. Client: Kullanici "Ana fotograf yap" secer
2. Client: photos array'ini yeniden sirala (secilen foto basa gelsin)
3. Client: PATCH /users/me { photos: [...yeniSira] }
4. Backend: Array'i kaydeder

NOT: Backend'de reorder icin ayri endpoint yok. Mevcut updateProfile ile photos array gonderilir.

## 7. Backend Validator Guncellemesi

updateProfileSchema'ya photos field'i eklenmeli:
```
photos: z.array(z.string().url()).max(6).optional()
```

## 8. Migration

```sql
-- supabase/migrations/006_badge_rewards.sql
ALTER TABLE users ADD COLUMN badge_rewards_claimed TEXT[] DEFAULT '{}';
```

## 9. i18n Anahtarlari

Yeni anahtarlar (TR + EN):
- profile.badge.rookie / profile.badge.popular / profile.badge.master
- profile.badge.progress_hint (parametreli: "{percent}% kaldi")
- profile.hint.add_photos / profile.hint.add_bio / profile.hint.add_job / ...
- profile.edit.title / profile.edit.save / profile.edit.photos_section / ...
- profile.edit.about / profile.edit.details / profile.edit.preferences
- profile.badge.reward_claimed ("Tebrikler! {count} mor elmas kazandin!")
- profile.badge.discover_warning ("Profilini tamamla, kesfette gorun!")

## 10. Etkilenen Dosyalar

### Yeni Dosyalar
- `lib/features/profile/screens/edit_profile_screen.dart`
- `lib/features/profile/widgets/photo_grid.dart`
- `lib/features/profile/widgets/badge_bar.dart`
- `lib/features/profile/widgets/detail_chips.dart`
- `server/src/routes/badge.routes.ts` veya user.routes.ts'e ekleme
- `server/src/services/badge.service.ts`
- `supabase/migrations/006_badge_rewards.sql`
- 10 yeni SVG ikon dosyasi

### Degisecek Dosyalar
- `lib/features/profile/screens/profile_screen.dart` (tamamen yeniden)
- `lib/core/constants/q_icons.dart` (yeni ikonlar)
- `lib/routing/` (edit_profile route)
- `lib/providers/user_provider.dart` (claimBadgeReward metodu)
- `lib/data/repositories/user_repository.dart` (reorder + badge)
- `lib/data/models/user_model.dart` (badge_rewards_claimed field)
- `server/src/validators/user.validator.ts` (photos array ekleme)
- `lib/core/l10n/` (yeni i18n key'leri)
