# Profile Preferences & Completion Incentive System - Tasarım

**Tarih:** 2026-03-09
**Durum:** Onaylandı

---

## 1. Kapsam

1. Mevcut tercihlerin doğrulanması + bug fix (gender_pref enum tutarsızlığı)
2. Yeni tercihler: ilişki amacı + dil tercihi
3. Edit profile ekranı kartlı tasarım
4. Profil tamamlama teşvik sistemi (karma: elmas + boost + rozet)

---

## 2. Bug Fix — Gender Pref Enum Tutarsızlığı

**Sorun:** Flutter'da `'MALE'`/`'FEMALE'`/`'ALL'` kullanılıyor olabilir, backend/DB'de `'MAN'`/`'WOMAN'`/`'BOTH'` enum tanımlı.

**Çözüm:**
- Flutter edit ekranındaki SegmentedButton değerlerinin backend enum'larıyla (`MAN`, `WOMAN`, `BOTH`) eşleştiğini doğrula
- Matching service'deki gender filtre mantığını kontrol et
- Age range ve distance filtrelerinin backend'de doğru uygulandığını kontrol et
- Varsa düzelt

---

## 3. Yeni Tercihler

### 3.1 İlişki Amacı (relationship_goal)

**DB Enum:** `relationship_goal_type` → `'SERIOUS'`, `'FRIENDSHIP'`, `'NOT_SURE'` (default: `NOT_SURE`)
**Users tablosuna:** `relationship_goal relationship_goal_type DEFAULT 'NOT_SURE'`

**Davranış:**
- Edit profile'da SegmentedButton ile 3 seçenek
- Discover card'da badge olarak görünür (ikon + label)
- **Filtre olarak kullanılmaz** — sadece bilgilendirme amaçlı
- Havuzu daraltmaz

### 3.2 Dil Tercihi (preferred_languages)

**DB:** `preferred_languages TEXT[]` (default: kullanıcının locale'i, ör. `'{tr}'`)
**Desteklenen diller:** tr, en, de, fr, ar, ru, es (7 dil)

**Davranış:**
- Multi-select chip seçimi
- Birden fazla dil seçilebilir
- `locale` alanından bağımsız — locale sadece UI dili, preferred_languages matching için
- Backend matching'de mevcut dil filtresini güçlendirir

---

## 4. Edit Profile — Kartlı Tasarım

### 4.1 ProfileSectionCard Widget

Ortak komponent: `lib/core/widgets/profile_section_card.dart`

**Yapı:**
- Subtle border: `AppColors.primary.withOpacity(0.15)` (mor neon hint)
- Background: `surfaceContainerLow`
- Başlık satırı: İkon + Başlık (titleMedium, bold) + sağ üstte tamamlama chip ("3/4 ✓")
- Açıklama: Başlık altında 1 satır helper text (bodySmall, onSurfaceVariant)
- İçerik: Kartın alt kısmında form elemanları
- Border radius: AppSpacing uyumlu

### 4.2 Section'lar (6 Kart)

| # | Başlık | Açıklama | İçerik | Tamamlama Sayacı |
|---|--------|----------|--------|------------------|
| 1 | Fotoğraflar | "İlk fotoğrafın profil fotoğrafın olur" | 6'lı photo grid | x/6 (1+ ve 3+ ayrı milestone) |
| 2 | Hakkımda | "Kendini kısaca tanıt" | Bio textarea (300 char) | 0/1 veya 1/1 |
| 3 | Temel Bilgiler | "Seni tanımamıza yardımcı ol" | İsim, şehir, boy, kilo | x/4 |
| 4 | Detaylar | "Profilini zenginleştir, daha fazla eşleşme al" | Burç, iş, okul, sigara, alkol, evcil hayvan, müzik, kişilik | x/8 |
| 5 | Tercihler | "Sana uygun kişileri görelim" | Cinsiyet, yaş aralığı, mesafe, dil tercihi | x/4 |
| 6 | İlişki Amacı | "Ne aradığını karşı taraf görsün" | 3'lü SegmentedButton (Ciddi/Arkadaşlık/Bilmiyorum) | 0/1 veya 1/1 |

### 4.3 Progress Bar

- Ekranın üstünde (kartların üzerinde) global progress bar + yüzde
- Milestone'a yakınsa motivasyon mesajı: "%75'e az kaldı! 30 elmas kazanmak için tamamla"
- Renk: primary (mor neon), doluluk animasyonlu

---

## 5. Profil Tamamlama Teşvik Sistemi

### 5.1 Güncellenen Formül

**Eski:** 14 alan → `(score / 14) * 100`
**Yeni:** 16 alan → `(score / 16) * 100`

**Alanlar (16):**

User alanları (7):
1. name
2. surname
3. bio
4. city
5. location (lat + lng)
6. 1+ fotoğraf
7. 3+ fotoğraf

Detail alanları (7):
8. height
9. weight
10. zodiac
11. job
12. school
13. smoking
14. alcohol

Yeni alanlar (2):
15. relationship_goal (NOT_SURE dışı bir değer seçilmişse)
16. preferred_languages (en az 1 seçili — default zaten locale olduğu için genelde dolu)

### 5.2 Elmas Ödülleri (Tek Seferlik)

| Milestone | Ödül | Tetikleyici |
|-----------|------|-------------|
| %25 | 5 mor elmas | İlk fotoğraf + temel bilgiler |
| %50 | 15 mor elmas | Detayların yarısı |
| %75 | 30 mor elmas | Çoğu alan dolu |
| %100 | 50 mor elmas | Her şey tamam |

**Toplam potansiyel:** 100 mor elmas

**Tracking:** `users` tablosuna `completion_rewards_claimed JSONB` alanı
- Örnek: `{"25": true, "50": true, "75": false, "100": false}`
- Ödül sadece 1 kez verilir
- Alan boşaltıp tekrar doldurunca tekrar verilmez

### 5.3 Görünürlük Boost

- Mevcut discover scoring'deki `profileScore` zaten tamamlama yüzdesini kullanıyor — ek bir şey gerek yok
- **%100 tamamlama** → 24 saatlik ücretsiz mini-boost (tek seferlik)
- `boost_until` alanı güncellenir

### 5.4 Rozet

- %100 tamamlama → `COMPLETE_PROFILE` badge tipi
- Profil ekranında ve discover card'da görünür
- Mevcut badge bar altyapısı kullanılır

### 5.5 Kullanıcı Bilgilendirme

- Progress bar üstünde motivasyon mesajları
- Milestone alındığında: konfeti animasyonu + elmas kazanım bottom sheet
- Bottom sheet: "Tebrikler! %50 tamamladın — 15 💎 kazandın!"

---

## 6. DB Migration (010)

```sql
-- Yeni enum
CREATE TYPE relationship_goal_type AS ENUM ('SERIOUS', 'FRIENDSHIP', 'NOT_SURE');

-- Users tablosuna yeni alanlar
ALTER TABLE users ADD COLUMN relationship_goal relationship_goal_type DEFAULT 'NOT_SURE';
ALTER TABLE users ADD COLUMN preferred_languages TEXT[] DEFAULT '{tr}';
ALTER TABLE users ADD COLUMN completion_rewards_claimed JSONB DEFAULT '{}';
```

---

## 7. Backend Değişiklikleri

- **user.service.ts:** Profil tamamlama formülü 16 alana güncelle
- **user.service.ts:** Milestone kontrol + elmas ödülü verme logic'i
- **user.validator.ts:** relationship_goal ve preferred_languages validation ekle
- **user.routes.ts:** PATCH /me'ye yeni alanlar
- **matching.service.ts:** preferred_languages filtresi güçlendir
- **matching.service.ts:** gender_pref enum doğrulama

---

## 8. Flutter Değişiklikleri

- **ProfileSectionCard:** Yeni ortak widget (`lib/core/widgets/`)
- **edit_profile_screen.dart:** Kartlı tasarıma refactor, yeni alanlar ekle
- **UserModel:** relationship_goal, preferred_languages, completion_rewards_claimed
- **editProfileProvider:** Yeni alan state yönetimi
- **profile_screen.dart:** relationship_goal badge gösterimi
- **Discover card:** relationship_goal badge
- **Milestone celebration:** Konfeti + bottom sheet widget
