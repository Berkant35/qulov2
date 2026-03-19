# Chat Media Sharing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Chat'te karşılıklı onay ile fotoğraf ve ses mesajı paylaşımı ekle.

**Architecture:** matches tablosuna media_enabled kolonları + media_requests tablosu ekle. Backend'de media istek/onay/disable endpoint'leri oluştur. Flutter'da istek kartı, fotoğraf görüntüleyici, ses kaydedici/oynatıcı widget'ları oluştur.

**Tech Stack:** Flutter + Riverpod (mobile), Node.js + Express + TypeScript (backend), Supabase PostgreSQL + Storage (DB/dosya), image_picker (fotoğraf), record package (ses kayıt), just_audio (ses oynatma)

---

## Task 1: Migration 017 — Media Sharing Tables

**Files:**
- Create: `supabase/migrations/017_chat_media_sharing.sql`

**Step 1: Migration dosyası oluştur**

```sql
-- 017_chat_media_sharing.sql
-- Karşılıklı onay ile medya paylaşımı

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

CREATE INDEX idx_media_requests_match ON media_requests(match_id, status);
```

**Step 2: Commit**

```bash
git add supabase/migrations/017_chat_media_sharing.sql
git commit -m "feat: add media sharing migration 017 — mutual consent columns and requests table"
```

---

## Task 2: Backend — Media Service

**Files:**
- Create: `server/src/services/media.service.ts`
- Create: `server/src/controllers/media.controller.ts`
- Create: `server/src/validators/media.validator.ts`
- Modify: `server/src/routes/chat.routes.ts:25-31`

**Step 1: media.validator.ts oluştur**

```typescript
import Joi from "joi";

export const respondMediaRequestSchema = Joi.object({
  action: Joi.string().valid("accept", "reject").required(),
});
```

**Step 2: media.service.ts oluştur**

MediaService class:

- `requestMedia(matchId, requesterId)`:
  - verifyMatchAccess (user is user1 or user2, match active)
  - Check if media already enabled for both → throw "Medya zaten aktif"
  - Check if pending request already exists → throw "Bekleyen istek var"
  - Insert media_requests (match_id, requester_id, status='pending')
  - Determine user position (user1 or user2)
  - Set media_enabled_by_userX = true on matches table for requester
  - Return request object

- `respondToRequest(requestId, userId, action)`:
  - Fetch request, verify pending
  - Verify userId != requester_id (cevaplayan karşı taraf olmalı)
  - verifyMatchAccess
  - If accept:
    - Update request status='accepted', responded_at=now()
    - Determine user position, set media_enabled_by_userX = true
    - Send push notification to requester: "Medya isteğin kabul edildi!"
  - If reject:
    - Update request status='rejected', responded_at=now()
    - Reset requester's media_enabled_by_userX = false
    - No push on reject (sessiz)
  - Return { status, media_enabled: both true? }

- `disableMedia(matchId, userId)`:
  - verifyMatchAccess
  - Reset BOTH media_enabled_by_user1 and media_enabled_by_user2 to false
  - Delete any pending media_requests for this match
  - Return success

- `getMediaStatus(matchId, userId)`:
  - verifyMatchAccess
  - Fetch match media columns
  - Fetch latest media_request for this match
  - Return { media_enabled: both true?, my_enabled, other_enabled, pending_request? }

- Private `verifyMatchAccess` — same pattern as chat.service.ts

**Step 3: media.controller.ts oluştur**

4 handlers: requestMediaHandler, respondToMediaRequestHandler, disableMediaHandler, getMediaStatusHandler

**Step 4: chat.routes.ts — yeni route'lar ekle**

```typescript
router.post("/:match_id/media-request", requestMediaHandler);
router.post("/:match_id/media-request/:id/respond", validate(respondMediaRequestSchema), respondToMediaRequestHandler);
router.post("/:match_id/media-disable", disableMediaHandler);
router.get("/:match_id/media-status", getMediaStatusHandler);
```

**Step 5: TypeScript compile kontrolü**

```bash
cd server && npx tsc --noEmit
```

**Step 6: Commit**

```bash
git add server/src/services/media.service.ts server/src/controllers/media.controller.ts server/src/validators/media.validator.ts server/src/routes/chat.routes.ts
git commit -m "feat(backend): add media sharing service — request, respond, disable, status"
```

---

## Task 3: Backend — Ses mesajı upload endpoint

**Files:**
- Modify: `server/src/services/chat.service.ts:62-91` (sendMessage güncelle)
- Modify: `server/src/validators/chat.validator.ts`

**Step 1: chat.validator.ts — sendMessage şemasını güncelle**

Mevcut content/is_image/page/limit'e ek olarak:

```typescript
// sendMessage schema'ya ekle:
audio_url: Joi.string().uri().optional(),
audio_duration_seconds: Joi.number().integer().min(1).max(60).optional(),
```

**Step 2: chat.service.ts — sendMessage'da medya kontrol**

sendMessage metodunun başına medya izni kontrolü ekle:

```typescript
async sendMessage(matchId: string, senderId: string, content: string, isImage: boolean, audioUrl?: string, audioDuration?: number) {
  const match = await this.verifyMatchAccess(matchId, senderId);

  // Medya kontrol: fotoğraf veya ses gönderiyorsa izin kontrolü
  if (isImage || audioUrl) {
    if (!match.media_enabled_by_user1 || !match.media_enabled_by_user2) {
      throw Errors.BAD_REQUEST("Medya paylaşımı için karşılıklı onay gerekiyor");
    }
  }

  // Insert message — audio alanlarını da ekle
  const insertData: any = {
    match_id: matchId,
    sender_id: senderId,
    content,
    is_image: isImage,
  };
  if (audioUrl) {
    insertData.audio_url = audioUrl;
    insertData.audio_duration_seconds = audioDuration;
  }

  // ... mevcut insert + push logic
}
```

verifyMatchAccess dönüş tipini güncelle — media kolonlarını da select'e ekle:

```typescript
private async verifyMatchAccess(matchId: string, userId: string) {
  const { data: match } = await supabase
    .from("matches")
    .select("id, user1_id, user2_id, is_active, media_enabled_by_user1, media_enabled_by_user2")
    // ... mevcut logic
  return match; // artık media alanlarını da içerir
}
```

**Step 3: Commit**

```bash
git add server/src/services/chat.service.ts server/src/validators/chat.validator.ts
git commit -m "feat(backend): add media permission check to sendMessage, support audio fields"
```

---

## Task 4: Flutter — Match Model + Media Status

**Files:**
- Modify: `lib/data/models/match_model.dart:7-26`
- Create: `lib/data/models/media_request_model.dart`

**Step 1: match_model.dart — media alanları ekle**

MatchModel'e ekle:

```dart
@JsonKey(name: 'media_enabled_by_user1')
final bool mediaEnabledByUser1;
@JsonKey(name: 'media_enabled_by_user2')
final bool mediaEnabledByUser2;
```

Constructor'da default false, props'a ekle.

Helper getter:
```dart
bool get isMediaEnabled => mediaEnabledByUser1 && mediaEnabledByUser2;
```

**Step 2: media_request_model.dart oluştur**

```dart
@JsonSerializable()
class MediaRequestModel extends Equatable {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'requester_id')
  final String requesterId;
  final String status; // pending, accepted, rejected
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'responded_at')
  final String? respondedAt;

  // ... constructor, fromJson, props
}

@JsonSerializable()
class MediaStatusResponse extends Equatable {
  @JsonKey(name: 'media_enabled')
  final bool mediaEnabled;
  @JsonKey(name: 'my_enabled')
  final bool myEnabled;
  @JsonKey(name: 'other_enabled')
  final bool otherEnabled;
  @JsonKey(name: 'pending_request')
  final MediaRequestModel? pendingRequest;

  // ... constructor, fromJson, props
}
```

**Step 3: build_runner çalıştır**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 4: Commit**

```bash
git add lib/data/models/match_model.dart lib/data/models/match_model.g.dart lib/data/models/media_request_model.dart lib/data/models/media_request_model.g.dart
git commit -m "feat: add media fields to match model, create media request model"
```

---

## Task 5: Flutter — Media Service + Chat Service Update

**Files:**
- Modify: `lib/core/network/services/chat_service.dart:27-38`
- Modify: `lib/data/repositories/chat_repository.dart`
- Modify: `lib/providers/api_provider.dart`

**Step 1: chat_service.dart — media endpoint'leri ekle**

```dart
@POST('/chat/{matchId}/media-request')
Future<MediaRequestModel> requestMedia(@Path('matchId') String matchId);

@POST('/chat/{matchId}/media-request/{requestId}/respond')
Future<Map<String, dynamic>> respondToMediaRequest(
  @Path('matchId') String matchId,
  @Path('requestId') String requestId,
  @Body() Map<String, dynamic> data,
);

@POST('/chat/{matchId}/media-disable')
Future<void> disableMedia(@Path('matchId') String matchId);

@GET('/chat/{matchId}/media-status')
Future<MediaStatusResponse> getMediaStatus(@Path('matchId') String matchId);
```

sendMessage metodunu güncelle — audio parametreleri ekle:
```dart
@POST('/chat/{matchId}/messages')
Future<MessageModel> sendMessage(
  @Path('matchId') String matchId,
  @Body() Map<String, dynamic> data, // content, is_image, audio_url, audio_duration_seconds
);
```

**Step 2: chat_repository.dart — media metodları ekle**

```dart
Future<Result<MediaRequestModel>> requestMedia(String matchId)
Future<Result<Map<String, dynamic>>> respondToMediaRequest(String matchId, String requestId, String action)
Future<Result<void>> disableMedia(String matchId)
Future<Result<MediaStatusResponse>> getMediaStatus(String matchId)
```

**Step 3: build_runner + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
git add lib/core/network/services/chat_service.dart lib/core/network/services/chat_service.g.dart lib/data/repositories/chat_repository.dart
git commit -m "feat: add media request/respond/disable/status API methods"
```

---

## Task 6: Flutter — Media Request Card Widget

**Files:**
- Create: `lib/features/chat/widgets/media_request_card.dart`

**Step 1: Widget oluştur**

Özel kart mesajı — chat'te gösterilir:

Props: requesterId, currentUserId, status, onAccept, onReject

Durumlar:
- **pending + ben gönderdim**: "Medya isteği gönderildi. Cevap bekleniyor..."
- **pending + karşı taraf gönderdi**: "📷 X medya paylaşmak istiyor" + [Kabul Et] / [Reddet] butonları
- **accepted**: "✓ Medya paylaşımı aktif" (yeşil border)
- **rejected**: "Medya isteği reddedildi" (gri, muted)

Tasarım:
- Container: surface bg, primary border (pending), success border (accepted), border.withOpacity(0.3) (rejected)
- İkon: camera icon (📷) veya Icons.photo_camera
- Butonlar: ElevatedButton (Kabul) + OutlinedButton (Reddet)

**Step 2: Commit**

```bash
git add lib/features/chat/widgets/media_request_card.dart
git commit -m "feat(chat): add media request card widget with accept/reject actions"
```

---

## Task 7: Flutter — Voice Recorder Overlay

**Files:**
- Create: `lib/features/chat/widgets/voice_recorder_overlay.dart`

**Step 1: Widget oluştur**

Ses kayıt UI — basılı tut mekaniği:

Props: onRecordComplete(String filePath, int durationSeconds), onCancel

Davranış:
- Widget görünür olduğunda kayıt başlar (record package kullanarak)
- Kırmızı dot + süre gösterimi (00:00 formatı) + "Bırak: Gönder | ↑ Kaydır: İptal"
- Ekranın alt kısmında overlay olarak gösterilir
- Max 60sn — otomatik durur
- Yukarı kaydırma (dy < -50) → iptal, dosya silinir
- Bırakma → kayıt durur, filePath ve süre döner

Teknik:
- `record` package (veya `flutter_sound`) ile ses kayıt — bu bir donanımsal paket, ImagePickerManager pattern'ı gibi bir AudioRecorderManager singleton oluşturulmalı (lib/core/services/)
- Geçici dosya: getTemporaryDirectory() + UUID.mp4
- Süre takibi: Timer.periodic ile saniye sayacı

> **NOT:** Donanımsal paket kuralı gereği, record/flutter_sound doğrudan widget'ta kullanılmaz. `lib/core/services/audio_recorder_manager.dart` singleton oluşturulmalı.

**Step 2: Commit**

```bash
git add lib/features/chat/widgets/voice_recorder_overlay.dart lib/core/services/audio_recorder_manager.dart
git commit -m "feat(chat): add voice recorder overlay with hold-to-record UX"
```

---

## Task 8: Flutter — Voice Message Widget (Oynatıcı)

**Files:**
- Create: `lib/features/chat/widgets/voice_message_widget.dart`

**Step 1: Widget oluştur**

Ses mesajı oynatma widget'ı — chat balonu içinde:

Props: audioUrl, durationSeconds, isMine (bool, balonu sağa/sola hizalar)

Tasarım:
- Container: gradient (isMine) veya gri (karşı taraf), radius 16
- Play/pause ikonu (sol)
- Progress bar (orta, linear)
- Süre gösterimi (sağ): "0:15 / 0:42"

Teknik:
- `just_audio` veya `audioplayers` ile oynatma
- AudioPlayerManager singleton (lib/core/services/) — donanımsal paket kuralı
- StreamBuilder ile position takibi
- Tek bir player instance — yeni bir ses başladığında önceki durur

**Step 2: Commit**

```bash
git add lib/features/chat/widgets/voice_message_widget.dart lib/core/services/audio_player_manager.dart
git commit -m "feat(chat): add voice message player widget with progress bar"
```

---

## Task 9: Flutter — Photo Message Widget + Full Screen Viewer

**Files:**
- Create: `lib/features/chat/widgets/photo_message_widget.dart`

**Step 1: Widget oluştur**

Fotoğraf mesaj gösterimi:

Props: imageUrl, isMine

Tasarım:
- CachedNetworkImage thumbnail (max width: 200, radius 12)
- Loading: shimmer placeholder
- Tıklayınca: full-screen hero animasyonlu görüntüleyici (InteractiveViewer ile zoom)
- Hata: broken image ikonu

Full screen viewer:
- Scaffold siyah bg
- AppBar transparan + geri butonu
- InteractiveViewer (pinch zoom)
- Hero animasyonu (tag: imageUrl)

**Step 2: Commit**

```bash
git add lib/features/chat/widgets/photo_message_widget.dart
git commit -m "feat(chat): add photo message widget with full-screen viewer"
```

---

## Task 10: Flutter — Chat Screen Entegrasyonu

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart`
- Modify: `lib/providers/chat_provider.dart`

**Step 1: Chat provider — media state ekle**

ChatState'e ekle:
```dart
bool mediaEnabled; // ikisi de onaylamış mı
MediaRequestModel? pendingMediaRequest;
```

ChatNotifier'a ekle:
```dart
Future<void> loadMediaStatus() // getMediaStatus API call
Future<void> requestMedia() // media-request API call
Future<void> respondToMediaRequest(String requestId, String action) // respond API call
Future<void> disableMedia() // media-disable API call
```

**Step 2: chat_screen.dart — medya entegrasyonu**

Input satırı değişiklikleri:
- Attachment butonu (📎 veya camera icon): Fotoğraf seç/çek
  - Tıklayınca: mediaEnabled kontrolü
  - İzin yoksa: "Medya paylaşmak için karşı tarafın da onay vermesi gerekiyor. İstek gönderilsin mi?" dialog
  - İzin varsa: ImagePickerManager ile fotoğraf seç, upload, sendMessage(isImage: true)

- Mikrofon butonu (send butonunun yanında):
  - mediaEnabled kontrolü — izin yoksa aynı dialog
  - İzin varsa: GestureDetector(onLongPressStart → kayıt başlat, onLongPressEnd → gönder, onLongPressMoveUpdate → iptal kontrolü)
  - VoiceRecorderOverlay göster

Mesaj listesi değişiklikleri:
- message.isImage → PhotoMessageWidget kullan
- message.isAudio → VoiceMessageWidget kullan
- message.isDeleted → mevcut "Bu mesaj silindi" text (zaten var)
- MediaRequestCard'ı chat akışına ekle (özel mesaj tipi)

AppBar menüsüne ekle:
- "Medya paylaşımını kapat" seçeneği (mediaEnabled ise)

Fotoğraf upload:
- ImagePickerManager.pickImage()
- Supabase Storage'a upload: `chat-media/{matchId}/{uuid}.jpg`
- URL'i sendMessage content'ine yaz, is_image: true

Ses upload:
- AudioRecorderManager ile kaydet
- Supabase Storage'a upload: `chat-media/{matchId}/{uuid}.m4a`
- sendMessage(content: 'Voice message', audioUrl: url, audioDuration: seconds)

**Step 3: Commit**

```bash
git add lib/features/chat/screens/chat_screen.dart lib/providers/chat_provider.dart
git commit -m "feat(chat): integrate media sharing — photo, voice, consent flow"
```

---

## Task 11: Analytics + Memory Güncellemesi

**Files:**
- Modify: `lib/core/services/analytics_events.dart`
- Modify: memory files

**Step 1: Analytics event'ler**

```dart
static const chatMediaRequest = 'chat_media_request';
static const chatMediaAccept = 'chat_media_accept';
static const chatMediaReject = 'chat_media_reject';
static const chatMediaDisable = 'chat_media_disable';
static const chatPhotoSend = 'chat_photo_send';
static const chatVoiceSend = 'chat_voice_send';
static const chatVoicePlay = 'chat_voice_play';
static const chatPhotoView = 'chat_photo_view';
```

**Step 2: Memory güncelle**

MEMORY.md:
- Son migration: 017 (chat_media_sharing)
- Çalıştırılmamış'a 017 ekle

completed-features.md'ye ekle:
- Chat Media Sharing (fotoğraf + ses, karşılıklı onay)

**Step 3: Commit**

```bash
git add lib/core/services/analytics_events.dart
git commit -m "feat(analytics): add chat media sharing events"
```

---

## Özet: Task Sıralaması

```
Task 1 (Migration)    → bağımsız
Task 2 (Backend service) → Task 1'e bağımlı (şema)
Task 3 (Backend sendMessage) → Task 2'ye bağımlı
Task 4 (Flutter models) → bağımsız
Task 5 (Flutter service) → Task 4'e bağımlı
Task 6 (Media request card) → bağımsız
Task 7 (Voice recorder) → bağımsız
Task 8 (Voice player) → bağımsız
Task 9 (Photo widget) → bağımsız
Task 10 (Chat entegrasyon) → Task 5-9'a bağımlı
Task 11 (Analytics) → en son
```

**Paralel gruplar:**
- Grup A: Task 1 → 2 → 3 (backend, sıralı)
- Grup B: Task 4 → 5 (Flutter data layer, sıralı)
- Grup C: Task 6, 7, 8, 9 (widget'lar, paralel)
- Grup D: Task 10 (entegrasyon, hepsine bağımlı)
- Grup E: Task 11 (en son)

**Tahmini commit sayısı:** 11
