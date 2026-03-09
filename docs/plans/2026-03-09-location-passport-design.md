# Location System & Passport Mode — Design

**Tarih:** 2026-03-09
**Durum:** Onaylandı

## Kararlar

- Pasaport konum seçimi: Google Maps harita + pin
- Konum alma zamanlaması: Discover ekranına girişte (lazy)
- Empty state: Inline slider (5-200km)
- Varsayılan match_radius_km: 50km
- Pasaport süresi: Süresiz (deaktive/reaktive = yeni 50 elmas)

---

## 1. Konum Sistemi (Tüm Kullanıcılar)

### Akış
1. Discover ekranına girildiğinde `LocationProvider.getCurrentLocation()` tetiklenir
2. İzin durumları:
   - **İlk kez**: İzin dialog → kabul → GPS → backend PATCH `/users/me/location`
   - **İzin var**: Sessizce GPS → backend güncelle
   - **İzin reddedilmiş**: "Konum izni gerekli" banner + ayarlara yönlendirme
   - **Servis kapalı**: "Konum servisini aç" yönlendirmesi
3. Reverse geocoding: lat/lng → şehir adı (`geocoding` paketi)
4. Backend'e `{ lat, lng, city }` gönderilir

### Edge Cases
- GPS timeout/hata: Son bilinen konum kullanılır, yoksa hata
- Konum >24 saat eski: Yeniden alınır
- Emülatör: Mock konum kabul edilir

---

## 2. Pasaport Modu (Premium)

### Erişim
- Sadece Premium (`subscription.hasPassport`)
- Free/Plus → upsell sheet (Premium'a yönlendir)
- Backend'de subscription tier kontrolü (client-side'a ek)

### Aktivasyon
1. Profil → "Pasaport Modu" butonu
2. Google Maps tam ekran açılır
3. Haritada pin bırak veya arama ile şehir bul
4. Reverse geocoding → şehir adı
5. "Buraya Taşın — 50 💎" onay
6. Elmas yeterliyse → `POST /passport/activate {city, lat, lng}`
7. Yetersizse → elmas satın alma yönlendirme
8. Başarılı → discover pasaport konumundan çalışır

### Deaktivasyon
- "Gerçek konumuna dön" butonu → `POST /passport/deactivate`
- Tekrar aktive = yeni 50 elmas

### Harita Ekranı
- Tam ekran Google Maps + üstte arama çubuğu
- Ortada sabit pin (harita hareket ettikçe pin sabit, bırakınca konum alınır)
- Altta: Seçilen şehir + onay butonu
- Sağ alt: Mevcut konum butonu

### Edge Cases
- Elmas yetersiz → satın alma yönlendirme
- Zaten aktif → `PASSPORT_ALREADY_ACTIVE` hatası (çift ödeme engeli)
- Pasaport aktifken discover kartında "Pasaport: İstanbul" badge
- Konum değiştirmek isterse → deaktive et + yeniden aktive et

---

## 3. Empty State & Mesafe Ayarı

### Profil Kalmadı UI
- Radar/konum ikonu
- "Yakınında gösterilecek profil kalmadı" başlık
- "Mesafe aralığını artırarak daha fazla kişi görebilirsin" açıklama

### Inline Slider
- Mevcut `match_radius_km` değeri
- 5-200km aralık, slider + "XX km" label
- "Yeniden Ara" butonu → radius güncelle + discover reload

### Pasaport İpucu
- Premium: "Ya da pasaport ile başka şehirleri keşfet →"
- Diğer: "Premium ile başka şehirleri keşfet" → upsell

### Edge Cases
- Max 200km + hâlâ profil yok → "Aktif kullanıcı bulunamadı, daha sonra dene"
- Konum izni yok → slider yerine izin yönlendirmesi
- Pasaport aktif + profil bitti → slider + "Farklı şehre taşın"

---

## 4. Backend Değişiklikleri

### API
- `PATCH /users/me/location`: Body'ye `city` eklenir
- `POST /passport/activate`: Subscription tier kontrolü eklenir
- `PATCH /users/me`: `match_radius_km` validasyonu (5-200)

### Güvenlik
- Passport backend gate: Premium tier doğrulaması
- Rate limiting: Mevcut yeterli
- Koordinat validasyonu: Mevcut yeterli

### DB
- `match_radius_km` default: 50 (migration ile)

---

## 5. Dosya Haritası

### Yeni
| Dosya | Amaç |
|-------|-------|
| `lib/features/passport/screens/map_picker_screen.dart` | Google Maps konum seçim |
| `lib/features/discover/widgets/empty_state_widget.dart` | Inline slider'lı empty state |

### Değiştirilecek
| Dosya | Değişiklik |
|-------|------------|
| `lib/providers/location_provider.dart` | Reverse geocoding + city |
| `lib/features/discover/screens/discover_screen.dart` | Konum tetikleme + empty state |
| `lib/features/passport/screens/passport_screen.dart` | Harita yönlendirme, lat=0 fix |
| `lib/providers/passport_provider.dart` | Subscription kontrolü |
| `server/src/services/passport.service.ts` | Tier kontrolü |
| `server/src/services/user.service.ts` | Location city ekleme |
| `server/src/validators/user.validator.ts` | city + radius validasyonu |
| `lib/core/l10n/app_localizations.dart` | Yeni i18n key'ler |
| `pubspec.yaml` | google_maps_flutter paketi |
| `lib/routing/route_config.dart` | map_picker route |

### Dokunulmayacak
- matching.service.ts (pasaport override zaten çalışıyor)
- scoring.service.ts
- Auth akışı
