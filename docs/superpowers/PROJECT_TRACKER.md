# Qulo V2 - Project Tracker

> Son guncelleme: 2026-03-13
> Branch: APP-1915

---

## Oturum: 2026-03-13 — Chat & Messaging Overhaul

### Tamamlanan Isler

| # | Baslik | Detay | Etkilenen Dosyalar |
|---|--------|-------|--------------------|
| 1 | Match creation fix | `quiz.service.ts` icerisinde `quiz_session_id` kolonu kaldirildi. Eslesmeler artik basariyla olusturuluyor. | `qulo-server: quiz.service.ts` |
| 2 | Mikrofon permission fix | Android `RECORD_AUDIO` permission + iOS `NSMicrophoneUsageDescription` eklendi. Mic button `onLongPress` yerine `onPressed` olarak degistirildi. | `AndroidManifest.xml`, `Info.plist`, chat input widget |
| 3 | Bottom nav hidden in chat | Chat route `parentNavigatorKey: rootNavigatorKey` ile root-level navigator'a tasindi. Chat acikken bottom nav gorunmuyor. | Router config, chat route tanimlamalari |
| 4 | Auto-scroll | `ScrollController` ile yeni mesaj geldiginde otomatik scroll eklendi. | Chat screen, message list widget |
| 5 | Quiz summary dismissable | `SharedPreferences` ile kapatma state'i persist ediliyor. Kullanici quiz summary'yi kapatinca tekrar gosterilmiyor. | Quiz summary widget, SharedPreferences integration |
| 6 | Last message + unread count | Backend'de paralel sorgular eklendi. Flutter `MatchModel`'e 4 yeni alan: `lastMessageText`, `lastMessageAt`, `lastMessageSenderId`, `unreadCount`. | `MatchModel`, matches API, match list UI |
| 7 | Chat pagination | `loadMore()` metodu + `hasMore` getter + scroll listener ile sonsuz scroll. Eski mesajlar yukari kaydirildiginda yukleniyor. | Chat notifier/provider, chat screen |
| 8 | Message timestamps | Gun ayiricilari (Bugun/Dun/tarih) + her mesajda saat gosterimi. | Chat message widget, date separator widget |
| 9 | Chat question system | `__QUESTION__:{id}` convention ile mesaj icerisinde soru gonderme. `ChatQuestionMessage` widget'i, diamond economy entegrasyonu, cache-first fetch stratejisi. | Chat message types, ChatQuestionMessage widget, diamond service |
| 10 | MediaRequestModel nullable fix | API'den null donen alanlar icin model alanlari nullable yapildi. Crash onlendi. | `MediaRequestModel` |

### Ozet Metrikler
- **Toplam tamamlanan:** 10 is
- **Backend degisiklik:** 3 (match creation, last message/unread, quiz service)
- **Frontend degisiklik:** 9 (hepsi Flutter tarafi)
- **Platform-specific:** 2 (Android + iOS permission)

---

## Bekleyen Isler / Backlog

### Yuksek Oncelik
| # | Baslik | Durum | Notlar |
|---|--------|-------|--------|
| 1 | Soru paketi gonderme (Question Packs) | Henuz baslanmadi | Chat icerisinde toplu soru gonderme mekanizmasi |
| 2 | 3 Agent yeniden deploy | Bekliyor | Railway/server tarafinda agent'larin guncellenmesi gerekiyor |
| 3 | Test asamasi | Devam ediyor | Chat flow, match creation, diamond economy uzerinde test |

### Diger Backlog (MEMORY.md'den)
| # | Baslik | Durum |
|---|--------|-------|
| 4 | Haftalik rapor cron job | Bekliyor |
| 5 | AI onerilerini toplu cache doldurma | Bekliyor |
| 6 | RevenueCat webhook kurulumu | Bekliyor |
| 7 | Deep link client tarafi implementasyonu | Bekliyor |

---

## Gecmis Oturumlar

> Onceki oturumlarda tamamlanan buyuk feature'lar (MEMORY.md referans):
> - Question System Overhaul (32 task, 16 phase)
> - Language System (20 task, 16 phase)
> - Notification System (16 task, 6 phase)
> - Location & Passport Mode (10 task, 10 phase)
> - Diamonds & IAP System (RevenueCat)
> - Navigation System (merkezi NavigationService)
> - Hardware Manager Pattern
> - Paywall & Lock Icon Sistemi
> - Discover Screen Refactor (widget extraction + mixin)
