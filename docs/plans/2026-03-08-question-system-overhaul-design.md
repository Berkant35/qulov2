# Qulo V2 — Question System Overhaul Design

## Genel Vizyon

Soru sistemi Qulo'nun kalbi — ama şu an bir dialog'a sıkıştırılmış. Bu overhaul ile soru hazırlama deneyimini tam ekran, AI destekli, gamified bir sürece dönüştürüyoruz. Amaç: kullanıcının kişisel, yaratıcı, Google'lanamaz sorular hazırlamasını kolaylaştırmak ve bu soruların ona yeşil elmas kazandırdığını her noktada hissettirmek.

### Temel Prensipler
- Kişisel sorular teşvik edilir, genel kültür değil
- Easy mode (AI) + Advanced mode (wizard) birlikte sunulur
- Analytics gamified — rozetler, zorluk dereceleri, kazanç takibi
- Soru sistemi app geneline yayılır (discover, profil, chat, bildirimler)
- Onboarding tatlı ve kademeli — zorlamaz, teşvik eder

---

## 1. Soru Oluşturma — İki Mod

### Easy Mode (AI Destekli)
- Kullanıcı kategori seçer (Kişilik, Müzik, Film, Seyahat, Yemek, vb.) veya "Profilime göre öner" der
- Kategori bazlı: backend'den cache'lenmiş öneriler gelir (önceden Gemini ile üretilmiş)
- Profil bazlı: gerçek zamanlı backend → Gemini API, kullanıcının bio/yaş/ilgi alanları bağlam olarak gönderilir
- 3-5 soru önerisi sunulur, kullanıcı beğendiğini seçer
- Seçilen soru düzenlenebilir (metin, şıklar, doğru cevap)
- Kaydet → bitti. 30 saniyede soru hazır
- AI her zaman kişisel sorular önerir — "Favori yemek tarifiniz?", "İlk buluşmada nereye gidersiniz?" tarzı

### Advanced Mode (Wizard)
- Adım 1: Soru metnini yaz + kategori seç (opsiyonel)
- Adım 2: 4 şıkkı gir + doğru cevabı işaretle
- Adım 3: İpucu ekle (opsiyonel) + süre preset'i seç (15sn ⚡ / 30sn Normal / 60sn 🧘 / 90sn 🧠)
- Adım 4: Kaydet
- Her adımda canlı preview — "Quiz çözen kişi bunu böyle görecek" mini kartı, timer dahil

### Ortak
- Soru metninin altında her zaman motto: "Seni anlatan sorular sor — cevabı Google'da bulunmasın"
- Mevcut dialog tamamen kaldırılır, tam ekran deneyime geçilir

---

## 2. Süre Preset Sistemi

| Preset | Süre | Etiket | Emoji |
|--------|------|--------|-------|
| Hızlı | 15sn | "Düşünme, hisset!" | ⚡ |
| Normal | 30sn | "Standart tempo" | ⏱️ |
| Rahat | 60sn | "Düşünmeye zaman var" | 🧘 |
| Düşündürücü | 90sn | "Zor soru hak eder" | 🧠 |

- Her soru için ayrı süre seçilebilir
- DB'de `time_limit` kolonu eklenir (default 30)
- Quiz backend'i soru bazlı süreyi kullanır (mevcut sabit 30sn yerine)
- Kısa süre = daha fazla güç kullanımı potansiyeli = daha fazla yeşil elmas

---

## 3. Soru Kategorileri

- Opsiyonel — kullanıcı seçmeyebilir
- Kategoriler: Kişilik, Müzik, Film, Spor, Seyahat, Yemek, Teknoloji, Genel, Diğer
- DB'de `category` kolonu (nullable string)
- Discover kartında tag olarak gösterilir: "Kişilik · Müzik"
- AI önerilerinde kategori seçimi doğal olarak zorunlu

---

## 4. Soru Analytics Dashboard (Gamified)

### Soru Bazlı Metrikler
- Doğru/yanlış oranı (pasta grafik veya bar)
- En çok seçilen şık (hangi şık kaç kez seçildi)
- Ortalama çözme süresi
- Güç kullanım dağılımı (Kopya: 12, Yarıya: 8, İpucu: 5, Süre Uzat: 3)
- Süre uzatma kullanım oranı
- Bu sorunun kazandırdığı toplam yeşil elmas

### Zorluk Rozeti Sistemi (Otomatik Hesaplanan)

| Rozet | Koşul | Renk |
|-------|-------|------|
| Kolay | Doğru oranı > %70 | Yeşil |
| Orta | Doğru oranı %40-%70 | Sarı |
| Zor | Doğru oranı %20-%40 | Turuncu |
| Efsanevi | Doğru oranı < %20 | Mor (glow efektli) |

- Minimum 10 çözülme sonrası rozet aktif olur
- "En İyi Sorun" badge'i: en çok yeşil elmas kazandıran soruya özel taç ikonu
- "Bu soru sana toplam 234 yeşil elmas kazandırdı" motivasyon metni her soru kartında

### Profil Vitrin Bölümü
- "Sorularım 847 kez çözüldü"
- "%34 başarı oranı"
- "2.450 yeşil elmas kazandım"
- Kendi profilinde görünür

---

## 5. Quiz Çözme Sonuç Ekranı (Gamified)

### Kısa Sonuç (Quiz Bitiminde)
- Doğru/yanlış sayısı
- Harcanan süre (toplam)
- Kullanılan güçler özeti
- Performans rozeti:

| Rozet | Koşul |
|-------|-------|
| Kusursuz | Tüm doğru, güç kullanmadan |
| Hızlı Çözücü | Ortalama süreden %50 hızlı |
| Güç Ustası | 3+ güç kullanarak tamamladı |
| Azimli | Son soruyu doğru bildi (öncekiler karışık) |

### Chat'te Detaylı Kart (Eşleşme Sonrası)
- Chat açıldığında üstte pinlenmiş "Quiz Özeti" kartı
- İkisi de görür: "3 soruyu 47sn'de çözdü, 1 Kopya Al kullandı"
- Buz kırıcı — sohbet başlatıcı
- Tıklanınca detaylı breakdown açılır

---

## 6. Düzenleme Kuyruğu Sistemi

### Kurallar
- Aktif quiz yoksa: düzenleme/silme anında uygulanır (mevcut davranış)
- Aktif quiz varsa: değişiklik kuyruğa girer
- Quiz bitince otomatik uygulanır
- Push bildirim: "Değişikliğin uygulandı"

### UI
- Soru kartında badge: "Düzenleme bekliyor" veya "Silme bekliyor"
- Soru ekranında "Bekleyen İşlemler" section'ı — liste halinde bekleyen değişiklikler
- Her bekleyen işlem iptal edilebilir

### DB
- `question_pending_changes` tablosu (type: UPDATE/DELETE, payload, status: PENDING/APPLIED/CANCELLED)

---

## 7. Onboarding (Kademeli)

### İlk Kayıt Sonrası (Bir Kez, SharedPreferences)
- 2-3 slide'lık tatlı animasyonlu tutorial:
  1. "Qulo'da eşleşmek için soru hazırla" — quiz akışı animasyonu
  2. "Seni anlatan sorular sor — Google'lanamaz olsun!" — kişisel soru örneği
  3. "Soruların çözüldükçe yeşil elmas kazan!" — yeşil elmas motivasyonu
- "Hemen Başla" veya "Sonra" butonu
- `onboarding_questions_seen` flag'i SharedPreferences'te

### Kademeli Nudge'lar (Mevcut Sisteme Ek)
- 1. giriş: Onboarding slide'ları
- 2. giriş: Discover kilit ekranında "Easy mode ile 30 saniyede soru hazırla!" CTA'sı
- 3. giriş: Easy mode bottom sheet otomatik açılır — AI soru önerileri sunulur
- Soru oluşturulduktan sonra nudge'lar durur

### Sürekli Motto'lar
- Soru oluşturma ekranında: "İpucu: 'En sevdiğim mevsim?' gibi seni anlatan sorular daha çok çözülür"
- Random rotate eden motivasyon cümleleri (5-10 adet)

---

## 8. App Genelinde Soru Entegrasyonu

### Discover Kartında
- Soru sayısı + zorluk badge'i: "5 soru · Zor"
- Kategori tag'leri: "Kişilik · Müzik"

### Profil Ekranında
- Vitrin bölümü: çözülme sayısı, başarı oranı, toplam yeşil elmas kazancı
- Soru dashboard'una geçiş butonu

### Chat Ekranında
- Eşleşme sonrası pinlenmiş quiz özeti kartı
- Buz kırıcı sohbet başlatıcı

### Haftalık Bildirim
- Push: "Bu hafta soruların 23 kez çözüldü, 156 yeşil elmas kazandın!"
- Inbox'ta detaylı kart: en zor soru, en çok güç kullanılan soru, toplam kazanç

---

## 9. Gemini AI Entegrasyonu

### Kategori Bazlı (Cache)
- Backend cron job veya admin trigger ile kategori başına 50-100 soru önceden üretilir
- `ai_question_suggestions` tablosu (category, question_text, answers, correct_answer, hint)
- Flutter'dan istek gelince cache'den rastgele 3-5 soru döner
- Hızlı, API maliyeti düşük

### Profil Bazlı (Gerçek Zamanlı)
- Flutter → Backend `POST /api/v1/questions/ai-suggest` endpoint'i
- Backend kullanıcının bio, yaş, cinsiyet, ilgi alanlarını Gemini'ye prompt olarak gönderir
- Prompt'ta vurgu: "Kişisel, Google'lanamaz, dating bağlamında anlamlı sorular üret"
- 3-5 öneri döner, kullanıcı seçer/düzenler
- Rate limit: günde max 10 istek

---

## 10. DB Değişiklikleri

### questions tablosu — yeni kolonlar
- `category` (TEXT, nullable)
- `time_limit` (INT, default 30)
- `stats_copy_used` (INT, default 0)
- `stats_half_used` (INT, default 0)
- `stats_hint_used` (INT, default 0)
- `stats_time_extend_used` (INT, default 0)
- `stats_skip_used` (INT, default 0)
- `stats_total_time_spent` (INT, default 0 — toplam saniye)
- `stats_solve_count` (INT, default 0)
- `stats_green_earned` (INT, default 0)

### Yeni tablolar
- `question_pending_changes` (id, question_id, user_id, change_type, payload, status, created_at, applied_at)
- `ai_question_suggestions` (id, category, question_text, answers JSONB, correct_answer, hint, locale, created_at)

### quiz_answers tablosu — yeni kolon
- `time_spent` (INT — bu soruya harcanan saniye)

---

## 11. Backend API Değişiklikleri

### Yeni Endpoint'ler
- `POST /api/v1/questions/ai-suggest` — AI soru önerileri (kategori veya profil bazlı)
- `GET /api/v1/questions/me/analytics` — Soru dashboard verileri
- `GET /api/v1/questions/me/weekly-report` — Haftalık rapor
- `POST /api/v1/questions/me/{orderNum}/queue-change` — Kuyruğa değişiklik ekle
- `DELETE /api/v1/questions/me/pending/{changeId}` — Bekleyen değişikliği iptal et
- `GET /api/v1/questions/me/pending` — Bekleyen değişiklikleri listele

### Değişen Endpoint'ler
- `POST /api/v1/questions/me` — category + time_limit alanları eklenir
- `PATCH /api/v1/questions/me/{orderNum}` — aktif quiz kontrolü + kuyruk mantığı
- `DELETE /api/v1/questions/me/{orderNum}` — aktif quiz kontrolü + kuyruk mantığı
- `POST /api/v1/quiz/{session_id}/answer` — güç istatistiklerini question'a yaz + time_spent kaydet

---

## 12. Kararlar Özeti

| Karar | Seçim |
|-------|-------|
| Soru oluşturma modu | Easy (AI) + Advanced (Wizard) |
| AI bağlam | Kategori (cache) + Profil (gerçek zamanlı) |
| Analytics | Gamified dashboard (rozetler + kazanç) |
| Süre ayarı | Preset'ler (15/30/60/90sn), soru bazlı |
| Onboarding | Kademeli (slide → nudge → easy mode öner) |
| Kategori | Opsiyonel |
| Düzenleme kısıtı | Aktif quiz → kuyruk, "Bekleyen İşlemler" bölümü |
| Quiz sonuç | Kısa gamified sonuç + chat'te detaylı kart |
| Haftalık rapor | Push + inbox kartı (kısa) |
| Canlı preview | Her adımda mini preview |
| Discover'da soru bilgisi | Soru sayısı + zorluk + kategori tag |
| Gemini API | Backend proxy (güvenlik) |
| Kişisel soru vurgusu | Onboarding + motto'lar + AI prompt |
