# Notification System - Design Document

## Goal
Push notification altyapısını tamamla, bildirim merkezi (inbox) ekle, backoffice'ten kampanya yönetimi ve segment bazlı hedefli bildirim gönderimi sağla.

## Kararlar
- **Hedef kitle:** Custom segment builder (cinsiyet, yaş, şehir, abonelik, aktiflik, profil tamamlanma, eşleşme durumu, kayıt tarihi)
- **Bildirim merkezi:** Zengin inbox — görsel + aksiyon butonu + in-app banner/popup
- **Kampanya analitiği:** Gönderildi/teslim/açıldı/tıklandı + segment bazlı breakdown + zaman grafiği
- **In-app banner:** Backoffice'ten manuel kampanya, tarih aralığı + segment
- **Deep link:** Dinamik action_url, GoRouter ile yönlendirme

---

## Veritabanı Şeması

### notifications
| Kolon | Tip | Açıklama |
|-------|-----|----------|
| id | UUID PK | |
| user_id | UUID FK → users | Alıcı |
| campaign_id | UUID FK → campaigns? | Kampanyadan geldiyse |
| type | TEXT | system, campaign, new_match, new_message, quiz_started, passport_expired |
| title | TEXT | Başlık |
| body | TEXT | İçerik |
| image_url | TEXT? | Görsel |
| action_url | TEXT? | Deep link |
| action_label | TEXT? | CTA butonu yazısı |
| is_read | BOOLEAN DEFAULT false | |
| created_at | TIMESTAMPTZ DEFAULT now() | |

### campaigns
| Kolon | Tip | Açıklama |
|-------|-----|----------|
| id | UUID PK | |
| title | TEXT | Admin görünen ad |
| push_title | TEXT | Push başlığı |
| push_body | TEXT | Push içeriği |
| image_url | TEXT? | Banner görseli |
| action_url | TEXT? | Deep link |
| action_label | TEXT? | CTA butonu |
| segment | JSONB | Hedef kitle filtresi |
| status | TEXT | draft, scheduled, sending, sent, cancelled |
| scheduled_at | TIMESTAMPTZ? | |
| sent_at | TIMESTAMPTZ? | |
| created_by | UUID FK → admin_users | |
| created_at | TIMESTAMPTZ DEFAULT now() | |

### campaign_stats
| Kolon | Tip | Açıklama |
|-------|-----|----------|
| id | UUID PK | |
| campaign_id | UUID FK UNIQUE | |
| total_targeted | INT DEFAULT 0 | |
| total_sent | INT DEFAULT 0 | |
| total_delivered | INT DEFAULT 0 | |
| total_opened | INT DEFAULT 0 | |
| total_clicked | INT DEFAULT 0 | |

### campaign_events
| Kolon | Tip | Açıklama |
|-------|-----|----------|
| id | UUID PK | |
| campaign_id | UUID FK | |
| user_id | UUID FK | |
| event | TEXT | sent, delivered, opened, clicked |
| created_at | TIMESTAMPTZ DEFAULT now() | |

### Segment JSONB Yapısı
```json
{
  "gender": "FEMALE",
  "age_min": 18,
  "age_max": 25,
  "cities": ["Istanbul", "Ankara"],
  "subscription_plan": "premium",
  "last_active_days": 7,
  "profile_completion_min": 0,
  "profile_completion_max": 50,
  "has_match": true,
  "registered_after": "2026-01-01"
}
```

---

## Backend Mimari

### NotificationService (Güncelleme)
Mevcut fire-and-forget yapı korunur, her bildirim artık notifications tablosuna da yazılır:
1. notifications tablosuna INSERT
2. FCM push gönder
3. Push başarısız olsa bile notification kaydı kalır

### CampaignService (Yeni)
- createCampaign(data) — Draft oluştur
- updateCampaign(id, data) — Draft düzenle
- scheduleCampaign(id, scheduledAt) — Zamanla
- sendCampaign(id) — Hemen gönder (batch 500)
- cancelCampaign(id) — İptal
- getCampaignStats(id) — Analitik
- previewSegmentCount(segment) — Segment'e uyan kullanıcı sayısı

Gönderim akışı:
1. Segment JSONB'den SQL WHERE oluştur
2. Hedef kullanıcıları çek (push_token'ı olanlar)
3. campaign_stats.total_targeted güncelle
4. Batch 500: notifications INSERT + FCM push
5. campaign_events INSERT (sent/delivered)
6. campaign_stats aggregate güncelle
7. Campaign status → sent

### API Endpoints (Kullanıcı)
```
GET    /api/v1/notifications              — Inbox (paginated)
GET    /api/v1/notifications/unread-count  — Okunmamış sayısı
PATCH  /api/v1/notifications/:id/read      — Okundu yap
POST   /api/v1/notifications/read-all      — Tümünü okundu yap
POST   /api/v1/notifications/:id/click     — CTA tıklama event'i
```

### Admin Routes (Yeni)
```
GET    /admin/campaigns              — Liste
GET    /admin/campaigns/new          — Oluşturma formu
POST   /admin/campaigns              — Oluştur
GET    /admin/campaigns/:id          — Detay + analitik
GET    /admin/campaigns/:id/edit     — Düzenleme formu
POST   /admin/campaigns/:id/update   — Güncelle
POST   /admin/campaigns/:id/send     — Gönder
POST   /admin/campaigns/:id/cancel   — İptal
POST   /admin/campaigns/preview-count — Segment count (AJAX)
```

### Mevcut Bildirimlerin action_url Mapping
- new_message → /matches/chat/{matchId}
- new_message_image → /matches/chat/{matchId}
- new_match → /matches
- quiz_started → /discover
- passport_expired → /profile/passport

---

## Flutter Mimari

### NotificationManager (Singleton)
`lib/core/services/notification_manager.dart`
- init() — FCM token al, listener kur
- getToken() — Mevcut token
- requestPermission() — Android 13+ runtime permission
- onTokenRefresh — Stream
- onForegroundMessage — Foreground handler
- onMessageOpenedApp — Tap handler
- onBackgroundMessage — Top-level function

### NotificationNotifier (Riverpod)
`lib/providers/notification_provider.dart`
- init() — Login sonrası çağrılır, token backend'e gönderilir
- fetchNotifications() — Inbox listesi
- unreadCount — Okunmamış sayısı
- markAsRead(id) — Tekil okundu
- markAllAsRead() — Toplu okundu
- trackClick(id) — CTA tıklama
- handleNotificationTap(data) — action_url'e GoRouter navigate

### Bildirim Merkezi UI
Route: /profile/notifications
- AppBar: "Bildirimler" + "Tümünü okundu yap"
- Profile ekranında çan ikonu + unread badge
- Bildirim kartları: görsel + başlık + body + zaman + okunmadı dot
- CTA butonu varsa ayrı buton
- Pull-to-refresh + infinite scroll

### In-App Banner
Foreground'da bildirim geldiğinde üstten kayan mini banner:
- Başlık + body (tek satır)
- 4 saniye gösterim
- Tıklanınca action_url'e git
- Swipe ile kapat

---

## Backoffice Kampanya Sayfası

### Kampanya Listesi (/admin/campaigns)
Tablo: Başlık | Segment özeti | Durum | Tarih | Hedef/Gönderilen/Açılan/Tıklanan

### Yeni Kampanya Formu (/admin/campaigns/new)
- İçerik: Push başlık, body, görsel URL, action URL, CTA label
- Segment builder: Cinsiyet, yaş aralığı, şehir(ler), abonelik, son aktiflik, profil tamamlanma, eşleşme durumu, kayıt tarihi
- Canlı önizleme: Segment'e uyan kullanıcı sayısı (AJAX count)
- Aksiyon: Hemen gönder veya zamanla

### Kampanya Detay (/admin/campaigns/:id)
- İçerik önizleme
- Analitik kartları: Hedef | Gönderilen | Açılan (%) | Tıklanan (%)
- Zaman grafiği: Gün bazlı trend
- Segment breakdown: Cinsiyet/şehir bazlı performans
