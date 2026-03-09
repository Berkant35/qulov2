# Qulo V2 — Dil Sistemi Tasarımı

## Genel Vizyon

Qulo soru-tabanlı eşleşme uygulaması — ama sorular tek dilde ve dil filtresi yok. Bu tasarım ile kullanıcıların birden fazla dil tercih edebilmesini, soruların dil etiketi taşımasını ve discover/quiz akışlarının dil-aware çalışmasını sağlıyoruz. Altyapı sınırsız dile hazır, app UI çevirisi aşamalı genişler.

### Temel Prensipler
- Kullanıcı bildiği dilleri seçer, discover sadece ortak dildeki profilleri getirir
- Her soruya dil etiketi atanır (otomatik + düzenlenebilir)
- Quiz'de sadece ortak dildeki sorular gösterilir
- Soru dili etiketi ≠ app UI dili (bağımsız kavramlar)
- Altyapı genişletilebilir: yeni dil eklemek config satırı

---

## 1. Kullanıcı Dil Tercihleri

### Seçim Mekanizması
- Kullanıcı "anlayabildiği diller" listesi seçer
- Sınırsız dil seçilebilir (kısıtlama yok)
- İlk kayıtta app locale otomatik eklenir (default)

### Ayarlama Noktaları
- **Onboarding**: Mevcut soru onboarding'ine ek slide — "Hangi dillerde soru çözebilirsin?"
- **Settings**: Dil tercihleri bölümü, ekle/çıkar

### DB
- `user_languages` tablosu (user_id UUID, language_code TEXT, created_at TIMESTAMPTZ)
- Primary key: (user_id, language_code)
- Foreign key: user_id → users(id)
- Kayıt sırasında app locale otomatik insert

---

## 2. Soru Dil Etiketi

### Atama Kuralı
- Her soruya `locale` kolonu eklenir (TEXT, NOT NULL)
- Soru oluşturmada app locale'den otomatik gelir
- Wizard'da küçük bir dil chip'i gösterilir (ör. "🇹🇷 Türkçe")
- Kullanıcı chip'e tıklayıp değiştirebilir (bottom sheet ile dil seçimi)

### Desteklenen Soru Dil Etiketleri
tr, en, de, fr, es, ar, ru, pt, it, ja, ko, zh, nl, pl, sv (15 dil)
- Config'den yönetilir, yeni dil eklemek tek satır
- App UI çevirisi bundan bağımsız (şimdilik tr/en)

---

## 3. Discover Filtreleme

### Eşleşme Kuralı
- Matching algoritmasına dil filtresi eklenir
- **Kural:** Karşı tarafın en az 2 sorusu kullanıcının bildiği dillerde olmalı
- 2+ ortak dil sorusu yoksa → profil discover'da gösterilmez
- Mevcut minimum 2 soru kuralı ile tutarlı

### Discover Kartı
- Soru dili chip'leri gösterilir (ör. "TR · EN")
- question_info'ya languages eklenir

---

## 4. Quiz Akışı

### Soru Filtreleme
- Quiz başladığında sadece ortak dildeki sorular gösterilir
- Farklı dildeki sorular atlanır (kullanıcı görmez)
- Quiz soru sayısı kişiye göre değişebilir
- Session süre hesabı: sadece gösterilen soruların time_limit toplamı

### Edge Case
- Ortak dil sorusu < 2 ise zaten discover'da gösterilmez → quiz'e ulaşmaz

---

## 5. AI Suggestions

### Dil Bağlantısı
- Wizard'daki dil chip'ine bağlı çalışır
- Chip "English" → AI İngilizce önerir
- Chip değişince yeni fetch tetiklenir
- Mevcut ai-suggest.service.ts zaten locale parametresi alıyor

---

## 6. DB Değişiklikleri

### Yeni Tablo
- `user_languages` (user_id, language_code, created_at)

### Değişen Tablolar
- `questions` → `locale TEXT NOT NULL DEFAULT 'tr'` kolonu eklenir
- `users` → `locale` constraint güncellenir (daha fazla dil kabul etmeli)

---

## 7. Backend API Değişiklikleri

### Yeni Endpoint'ler
- `GET /api/v1/users/me/languages` — Kullanıcının dil tercihlerini getir
- `PUT /api/v1/users/me/languages` — Dil tercihlerini güncelle (tam liste gönderilir)

### Değişen Endpoint'ler
- `POST /api/v1/questions/me` — locale alanı eklenir
- `PATCH /api/v1/questions/me/:orderNum` — locale düzenlenebilir
- Matching service — dil filtresi eklenir
- Quiz service — soru filtreleme + süre hesabı güncellenir
- Auth register — otomatik user_languages insert

### Değişen Validator'lar
- question validator — locale alanı (SUPPORTED_LOCALES listesinden)
- user validator — languages array

---

## 8. Flutter Değişiklikleri

### Yeni Ekranlar/Widget'lar
- Language picker bottom sheet (multi-select chip grid)
- Onboarding slide (dil seçimi)
- Settings'te dil tercihleri section'ı

### Değişen Ekranlar
- Question wizard — dil chip'i eklenir (Step 1'de)
- Discover kartı — dil chip'leri
- Settings — dil tercihleri bölümü

### Yeni Model/Provider
- UserLanguageModel (veya basit List<String>)
- userLanguagesProvider

---

## 9. Desteklenen Diller Config

```dart
// Flutter
const kSupportedQuestionLocales = [
  'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru',
  'pt', 'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv',
];
```

```typescript
// Backend
export const SUPPORTED_LOCALES = [
  'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru',
  'pt', 'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv',
] as const;
```

---

## 10. Kararlar Özeti

| Karar | Seçim |
|-------|-------|
| Dil eşleşme stratejisi | Preferred + Fallback (kullanıcı dil listesi seçer) |
| Soruya dil atama | Otomatik (system locale) + düzenlenebilir chip |
| Başlangıç dil seti | 15 soru etiketi, app UI tr/en kalır |
| Dil tercihi ayarlama | Onboarding + Settings |
| Mevcut veri | Production öncesi sıfırlanacak, migration sadece yeni yapı |
| Dil seçim limiti | Sınırsız |
| Discover filtresi | Karşı tarafta 2+ ortak dil sorusu olmalı |
| Quiz'de farklı dil | Sadece ortak dildeki sorular gösterilir, diğerleri atlanır |
| AI suggestions dili | Wizard'daki dil chip'ine bağlı |
