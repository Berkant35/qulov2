# Chat Media Sharing Design (Photo + Voice)

**Tarih:** 2026-03-09
**Durum:** Onaylandı

---

## Medya Onay Sistemi

- Karşılıklı onay: İki taraf da onaylamalı
- Tetikleme: Kullanıcı fotoğraf/ses ikonuna basınca, izin yoksa dialog → istek gönder
- Chat'te özel kart: "X medya paylaşmak istiyor" + [Kabul Et] / [Reddet]
- Kabul → ikisi de fotoğraf + ses gönderebilir
- Red → "X medya isteğini reddetti"
- Kalıcı ama geri alınabilir: "..." menüsünden kapatılabilir, yeniden istek gerekir
- Tek onay = fotoğraf + ses birlikte açılır

## Fotoğraf Gönderimi

- ImagePickerManager üzerinden (mevcut singleton)
- Supabase Storage'a upload → URL mesaja
- messages.is_image = true, content = image_url
- CachedNetworkImage thumbnail, tıklayınca full-screen

## Ses Mesajı

- Basılı tut = kayıt, bırak = gönder, yukarı kaydır = iptal
- Kayıt: kırmızı dot + süre + waveform animasyonu
- Max 60sn
- Supabase Storage upload → messages.audio_url + audio_duration_seconds
- Oynatma: waveform + play/pause + süre

## DB (Migration 017)

```sql
ALTER TABLE matches ADD COLUMN media_enabled_by_user1 BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE matches ADD COLUMN media_enabled_by_user2 BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE media_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at TIMESTAMPTZ
);
```

## Backend Endpoints

- POST /chat/:match_id/media-request
- POST /chat/:match_id/media-request/:id/respond (action: accept|reject)
- POST /chat/:match_id/media-disable
- GET /chat/:match_id/media-status

## Flutter Dosyaları

- media_request_card.dart — istek kart widget
- voice_message_widget.dart — ses oynatıcı
- voice_recorder_overlay.dart — kayıt UI
- photo_message_widget.dart — fotoğraf mesaj gösterimi
