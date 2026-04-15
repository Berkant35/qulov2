# Question Drag & Drop Reorder

## Problem
Kullanıcı sorularının sıralamasını değiştiremiyor. Soru silme sonrası order_num'lar otomatik düzeltiliyor ama kullanıcı kendi istediği sıralamayı yapamıyor.

## Çözüm
My Questions ekranında drag & drop ile soru sıralama. Flutter `ReorderableListView` + server batch reorder endpoint.

## Akış
1. Kullanıcı soru kartının drag handle'ından tutar ve sürükler
2. Bıraktığında yeni sıralama client'ta anında güncellenir (optimistic)
3. Server'a `PATCH /questions/me/reorder` isteği gider: `{ order: [id1, id2, id3, id4] }`
4. Server verilen sırayla `order_num` değerlerini günceller
5. Hata olursa client eski sıralamaya geri döner

## Server Değişiklikleri

### Yeni Endpoint: `PATCH /questions/me/reorder`
- **Body:** `{ order: string[] }` — soru UUID'lerinin istenen sırada dizisi
- **Validasyon:** Tüm ID'ler kullanıcıya ait olmalı, eksik/fazla ID olmamalı
- **İşlem:** Her ID'ye sırasına göre `order_num` (1, 2, 3...) ata
- **Response:** `200 OK` — güncellenmiş soru listesi

### Dosyalar
- `question.routes.ts` — `PATCH /me/reorder` route
- `question.controller.ts` — `reorderQuestionsHandler`
- `question.service.ts` — `reorderByIds(userId, orderedIds)` public metot
- `question.validator.ts` — `reorderSchema: { order: z.array(z.string().uuid()) }`

## Flutter Değişiklikleri

### UI
- `questions_screen.dart` — `ListView` → `ReorderableListView`, `onReorder` callback
- `questions_list_card.dart` — Sağ tarafa `Icons.drag_handle` ikonu ekleme (drag affordance)

### Data Layer
- `question_provider.dart` — `reorderQuestions(oldIndex, newIndex)` metodu (optimistic update + rollback)
- `question_repository.dart` — `reorderQuestions(List<String> orderedIds)`
- `question_service.dart` — `@PATCH('/me/reorder')` retrofit tanımı

## Tasarım Detayları
- **Optimistic update:** Sürükleme anında listeyi hemen güncelle, server hata dönerse rollback
- **Dismissible uyumu:** ReorderableListView long-press ile çalışır, Dismissible swipe ile — çakışma yok
- **Mevcut `reorderQuestions()` private metodu:** Silme sonrası otomatik çalışmaya devam eder, yeni `reorderByIds()` ayrı public metot
- **Haptic feedback:** Sürükleme başladığında hafif titreşim (HapticFeedback.mediumImpact)
