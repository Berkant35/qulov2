# Quiz → Match → Chat Full Flow Design

**Tarih:** 2026-03-09
**Durum:** Onaylandı

---

## 1. Discover Ekranı

### Kart Mekaniği
- Kart kaydırma (swipe) YOK — profil kartı sabit durur
- "Soruları Çöz" butonu: Ana aksiyon, dramatik tasarım (mavi gradient, büyük)
- "Geç" butonu (❌): Reject için
- Question Gate: Min 2 soru olmayan kullanıcılar blur + lock overlay

### Quiz'e Geçiş Animasyonu
- **Zoom-in geçiş** (B seçimi): Butona basınca kart ekranı kaplar → 0.5sn fade → quiz ekranı açılır
- Hızlı ve şık, tekrarlanan kullanımda bıktırmaz

---

## 2. Quiz Ekranı

### Temel Mekanik
- **Hardcore mod**: Tek yanlış = session FAILED, quiz biter
- Power'lar güvenlik ağı (ORACLE, SKIP, SKIP_ALL, HALF, HINT, TIME_EXTEND)
- Power kullanımı green diamond harcar

### Cevap Mekaniği (Seç + Onayla)
1. Şıkka tık → mor highlight ile seçilir
2. Altta "Cevapla" butonu belirir
3. "Cevapla"ya basınca gönderilir
4. Timer bu sürede DURMAZ — gerilim devam eder
5. Yanlışlıkla tıklama riski sıfıra iner

### Cevap Feedback
- **Doğru**: Buton yeşile döner + checkmark animasyonu + "Correct!" (0.8sn) → sonraki soru slide-in
- **Yanlış**: Buton kırmızı + X animasyonu + doğru cevap gösterilir (1.5sn) → session FAILED ekranı

### Timer Gerilim Katmanları
- **Normal**: Yeşil progress bar + saniye gösterimi
- **Son 10sn**: Kırmızıya döner + pulse animasyonu
- **Son 5sn**: Hafif ekran shake + tick-tock (ses açıksa, settings'ten toggle)
- **Süre doldu**: "Süre Doldu!" overlay → FAILED

### Çıkış Koruması
- Back butonu veya swipe-back → ConfirmDialog:
  > "Emin misin? Matchleşme şansından vazgeçiyorsun!"
  > [Vazgeç] / [Devam Et]
- Timer arka planda saymaya devam eder

### Power Bar
- Yatay scroll, 6 power chip'i
- Her power'da inventory sayısı badge'i
- Kullanımda green diamond düşer

---

## 3. Match Kutlama (Badge Odaklı)

### Akış
1. Son doğru cevap → yeşil flash
2. Tam ekran overlay açılır
3. Performance badge büyük animasyonla iner
4. İki kullanıcının fotoğrafları gösterilir
5. Quiz stats özet (doğru sayısı, süre, power kullanımı)
6. "Send a Message" butonu → chat ekranına geçiş

### Performance Badge Kuralları
| Badge | Koşul |
|-------|-------|
| **FLAWLESS** | Tüm doğru + sıfır power kullanımı |
| **SPEED SOLVER** | Toplam süre < soru sayısı × 15sn |
| **POWER MASTER** | 3+ power kullanımı |
| **DETERMINED** | Tüm doğru (power kullanmış) |
| **NONE** | Diğer durumlar |

---

## 4. Bildirim Stratejisi

| Olay | Push Notification | In-App Banner |
|------|-------------------|---------------|
| Quiz başladı | YOK | Evet (uygulama açıksa) |
| Match oluştu | EVET (badge bilgisiyle) | Evet |
| Yeni mesaj | EVET | Evet |

### Match Push İçeriği
- Zengin içerik: "Birisi sorularını [BADGE] çözdü! Yeni eşleşmen var!"
- Ör: "Birisi sorularını FLAWLESS çözdü! Yeni eşleşmen var!"

### Target Kullanıcı Deneyimi
- Quiz başladığında: Push YOK, uygulama içindeyse in-app banner ("Birisi sorularını çözüyor...")
- Match olunca: Push EVET (badge bilgisiyle)
- Chat'te: Quiz summary card her iki tarafta da görünür

---

## 5. Chat Ekranı

### Mevcut (Zaten Hazır)
- Supabase Realtime mesajlaşma
- Read receipts (read_at tracking)
- Quiz summary card (mesaj listesi üstünde)
- Image gönderimi
- In-app banner (foreground push)

### Yeni Eklenecek Özellikler

#### 5a. Typing Indicator
- Supabase Realtime presence veya custom channel ile "yazıyor..." göstergesi
- Mesaj input'una yazarken karşı tarafa broadcast
- 3sn inactivity sonrası kaybolur

#### 5b. Online/Offline Durumu
- Yeşil nokta: online (son 5dk içinde aktif)
- Gri nokta: offline
- Chat header'da kullanıcı adının yanında gösterilir
- Son görülme zamanı: "Son görülme: 2 saat önce"

#### 5c. Mesaj Silme
- Uzun basma → "Mesajı Sil" seçeneği (sadece kendi mesajları)
- Silinen mesaj yerine "Bu mesaj silindi" placeholder'ı
- Karşı taraf da "Bu mesaj silindi" görür

#### 5d. Reaction
- Uzun basma → emoji reaction picker (6-8 temel emoji: ❤️ 😂 😮 😢 👍 🔥)
- Mesaj balonunun altında küçük emoji badge'i
- Birden fazla reaction olabilir

#### 5e. Ses Mesajı
- Mikrofon butonu (send butonunun yanında)
- Basılı tut = kayıt, bırak = gönder
- Yukarı kaydır = iptal
- Waveform gösterimi (oynatma sırasında)
- Max süre: 60sn

#### 5f. Unmatch Akışı
- Chat header'da "..." menü → "Unmatch" seçeneği
- ConfirmDialog: "Bu kişiyle eşleşmeyi kaldırmak istediğine emin misin? Bu işlem geri alınamaz."
- Unmatch sonrası: Chat silinir, match listesinden kaldırılır

---

## 6. Chat İçi Soru Sistemi (Yeni Feature)

### Konsept
Matchleşmiş kullanıcılar chat içinde birbirine 2 şıklı custom soru gönderebilir.
Opsiyonel olarak "yanlış cevaplarsa unmatch" riski eklenebilir.

### Soru Hazırlama Akışı
1. Chat input'unda "?" ikonu veya özel buton → soru oluşturma bottom sheet açılır
2. Kullanıcı soruyu yazar (ör. "Tatilde plaj mı dağ mı?")
3. 2 şık belirler (A ve B)
4. Birini "doğru" olarak işaretler
5. Toggle: "Yanlış cevaplarsa unmatch olsun mu?" (default: kapalı)
6. Gönder

### Diamond Maliyeti (Risk Bazlı)
| Soru Tipi | Maliyet |
|-----------|---------|
| Normal soru (unmatch riski yok) | 5 purple diamond |
| Riskli soru (unmatch riski var) | 15 purple diamond |

### Günlük Limitler
- Max 2 soru/gün (aynı match'e)
- Unmatch riskli max 1 soru/gün
- Gece 00:00'da resetlenir

### Karşı Taraf Deneyimi
- Chat'te özel soru kartı mesajı görünür
- **Normal soru**: Mor kart, 2 şık butonu, eğlenceli tasarım
- **Riskli soru**: Kırmızı uyarı badge'i: "⚠️ Bu soru riskli!" — karşı taraf unmatch riskini biliyor
- Şıkka tıkla → sonuç gösterilir:
  - **Doğru**: Yeşil feedback + "Doğru bildin!" + soran kişi bilgilendirilir
  - **Yanlış (normal)**: Kırmızı feedback + doğru cevap gösterilir
  - **Yanlış (riskli)**: Kırmızı feedback + "Unmatch" uyarısı → otomatik unmatch

### Cevap Süresi
- Soru kartı süresiz bekler (timer yok) — chat'te doğal akış
- Cevaplanmamış sorular chat'te kart olarak durur

---

## 7. Blocker Fix'leri

### Migration 015: quiz_sessions.total_questions
```sql
ALTER TABLE quiz_sessions ADD COLUMN total_questions INT NOT NULL DEFAULT 0;
```

### Migration 014: Supabase'de Çalıştır
- `014_referral_system.sql` — Supabase SQL Editor'dan execute et
- `users.referral_code` + `referrals` tablosu oluşacak
- Location update 500 hatası düzelecek

---

## 8. Yeni DB Gereksinimleri

### Migration 015 (veya 016): Chat Enhancements
```sql
-- Chat içi sorular
CREATE TABLE chat_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('A', 'B')),
  has_unmatch_risk BOOLEAN NOT NULL DEFAULT false,
  diamond_cost INT NOT NULL DEFAULT 5,
  answered_option CHAR(1) CHECK (answered_option IN ('A', 'B')),
  is_correct BOOLEAN,
  answered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Message reactions
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);

-- Messages tablosuna soft delete
ALTER TABLE messages ADD COLUMN deleted_at TIMESTAMPTZ;

-- Ses mesajları için
ALTER TABLE messages ADD COLUMN audio_url TEXT;
ALTER TABLE messages ADD COLUMN audio_duration_seconds INT;
```

### Indexes
```sql
CREATE INDEX idx_chat_questions_match ON chat_questions(match_id);
CREATE INDEX idx_chat_questions_sender ON chat_questions(sender_id);
CREATE INDEX idx_message_reactions_message ON message_reactions(message_id);
CREATE INDEX idx_messages_deleted ON messages(match_id, created_at) WHERE deleted_at IS NULL;
```

---

## 9. Teknik Özet

### Backend Yeni Endpoint'ler
- `POST /chat/:match_id/questions` — Soru gönder
- `POST /chat/:match_id/questions/:id/answer` — Soruyu cevapla
- `POST /chat/:match_id/messages/:id/reactions` — Reaction ekle
- `DELETE /chat/:match_id/messages/:id/reactions/:emoji` — Reaction kaldır
- `DELETE /chat/:match_id/messages/:id` — Mesaj sil (soft delete)
- `POST /chat/:match_id/typing` — Typing indicator broadcast

### Flutter Yeni Dosyalar
- `lib/features/chat/widgets/chat_question_card.dart` — Soru kartı widget
- `lib/features/chat/widgets/reaction_picker.dart` — Emoji reaction picker
- `lib/features/chat/widgets/voice_message_widget.dart` — Ses mesajı widget
- `lib/features/chat/widgets/typing_indicator.dart` — Yazıyor göstergesi
- `lib/features/chat/sheets/create_question_sheet.dart` — Soru oluşturma bottom sheet
- `lib/features/quiz/widgets/match_celebration_screen.dart` — Badge odaklı kutlama tam ekranı
- `lib/data/models/chat_question_model.dart` — Chat soru modeli

### Değişecek Mevcut Dosyalar
- `quiz_screen.dart` — Seç+onayla mekaniği, timer katmanları, çıkış koruması
- `answer_button.dart` — Selectable mode eklenmesi
- `quiz_timer.dart` — Renk geçişleri, pulse, shake
- `quiz_result_dialog.dart` → `match_celebration_screen.dart`'a dönüşecek
- `chat_screen.dart` — Typing, reactions, delete, voice, chat questions
- `discover_screen.dart` — Zoom-in geçiş animasyonu
- `notification.service.ts` — quiz_started push kaldır, match push badge bilgisi ekle
- `quiz.service.ts` — total_questions fix
- `chat.service.ts` — Yeni endpoint'ler (questions, reactions, delete, typing)
- `chat.routes.ts` — Yeni route'lar
