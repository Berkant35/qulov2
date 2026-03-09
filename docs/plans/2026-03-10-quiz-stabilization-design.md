# Quiz Sistemi Stabilizasyon — Design Document

**Tarih:** 2026-03-10
**Durum:** Onaylandı

---

## 1. Yanlış Cevap Sonrası SKIP Kurtulma Mekaniği

### Akış
1. Kullanıcı yanlış cevap verir
2. "Wrong!" overlay gösterilir + altında SKIP teklif kartı:
   - Envanterde SKIP varsa: "SKIP kullan (×N hakkın var)" + yeşil buton
   - Envanterde yoksa: "SKIP satın al — 20 💎" + mor buton
   - "Vazgeç" butonu → session FAILED
3. Timer bu sırada DURUR (kullanıcıya karar süresi)
4. SKIP kullanırsa → yanlış cevap override edilir (is_correct: true, power_used: 'SKIP'), sonraki soruya geçilir
5. Vazgeçerse → session FAILED → celebration (failed) ekranı

### Backend Değişikliği
- Yanlış cevap geldiğinde session'ı hemen FAILED yapmak yerine `WRONG_PENDING` ara durumu
- Client SKIP gönderirse: yanlış cevabı override et, devam et
- Client vazgeçerse (veya timeout): FAILED olarak kapat
- Alternatif (daha basit): Yanlış cevap sonucu client'a `is_correct: false, session_status: 'IN_PROGRESS'` dön, session'ı henüz FAILED yapma. Client SKIP kullanırsa ayrı bir call ile override et. Belirli süre içinde SKIP gelmezse session expire olur.

### Seçilen Yaklaşım
Backend yanlış cevabı kaydeder ama session'ı hemen FAILED yapmaz — `is_correct: false, session_status: 'IN_PROGRESS'` döner. Client'a kurtulma şansı verir. Client ya SKIP power ile override eder (yeni endpoint: `POST /quiz/:session_id/rescue`), ya da vazgeçer (`POST /quiz/:session_id/fail`). Session expire süresi bu bekleme süresini de kapsar.

---

## 2. Power Kullanım Bug Fix'leri

| Bug | Kök Neden | Çözüm |
|-----|-----------|-------|
| `_answer(1, powerUsed: power)` sabit index | PowerBar'dan güç kullanıldığında hardcoded `1` gönderiliyor | Power kullanımını ayrı `_usePower(power)` metodu yap, `selected_answer` göndermeden sadece power'ı gönder |
| Power sonrası stopwatch durmuş | `_answer()` içinde `_stopwatch.stop()` yapılıyor, awaiting_answer dönüşünde restart yok | `awaitingAnswer: true` dönüşünde `_startQuestionTimer()` çağır |
| `_totalTimeSpent` çift sayılıyor | Power call + asıl cevap call'da her ikisinde de ekleniyor | Power kullanımında timeSpent ekleme, sadece asıl cevap gönderiminde ekle |
| `_powersUsed` yanlış artıyor | Her `_answer` çağrısında power varsa artırılıyor | Sayacı sadece backend'den başarılı power dönüşünde artır |

---

## 3. Timer Sorunları Fix

| Bug | Kök Neden | Çözüm |
|-----|-----------|-------|
| Timeout'ta `_answer(1)` sabit cevap | Timer bitince rastgele `1` gönderiliyor | Timeout'ta: eğer SKIP kurtulma mekaniği aktifse SKIP teklif et, değilse session'ı FAILED yap |
| Feedback sırasında timer devam | Timer widget feedback overlay'inden bağımsız | Feedback gösterilirken timer'ı pause et (state flag ile) |
| Time Extend timer'ı sıfırlıyor | ValueKey değişince widget rebuild, kalan süre kaybolur | Timer'a `addSeconds(int)` methodu ekle, key değiştirmek yerine internal state güncelle |

---

## 4. Matching Akışı

- Badge hesaplaması sadece backend'den alınacak (frontend kendi hesaplamayacak)
- `completeSession()` response'una badge bilgisi eklenecek
- Celebration ekranı backend'den gelen badge'i kullanacak

---

## 5. State Management İyileştirmesi

- `QuizNotifier.answer()` sırasında `isLoading: true` kaldırılacak — answer submission için local `_isSubmitting` yeterli
- Provider sadece session/question state için kullanılacak, UI feedback state'i local kalacak

---

## 6. Yeni Backend Endpoint'ler

```
POST /quiz/:session_id/rescue
  — Yanlış cevap sonrası SKIP ile kurtulma
  — Body: { power_used: 'SKIP' }
  — Mantık: Envanter kontrolü → elmas ödemesi → yanlış cevabı override → sonraki soruya geç
  — Response: { is_correct: true, next_question: N, session_status: 'IN_PROGRESS' | 'COMPLETED' }

POST /quiz/:session_id/fail
  — Kullanıcı kurtulmayı reddetti
  — Session'ı FAILED yap
  — Response: { session_status: 'FAILED' }
```

---

## 7. Flutter UI Değişiklikleri

### Wrong Answer Overlay (Yeni)
- "Wrong!" ikonu + animasyon (mevcut)
- SKIP teklif kartı: PowerIcon + fiyat/envanter + CTA buton
- "Vazgeç" secondary buton
- Timer duraklatılmış durumda

### Power Bar
- Power kullanımı `_usePower()` üzerinden (artık `_answer(1)` değil)
- Backend'e sadece power_used gönderilir, selected_answer gönderilmez

### Quiz Timer
- `addSeconds()` desteği (Time Extend için)
- Pause/resume desteği (feedback/rescue sırasında)

---

## 8. Özet Değişiklik Listesi

### Backend
- `quiz.service.ts`: Yanlış cevap → session'ı hemen FAILED yapma, IN_PROGRESS tut
- `quiz.service.ts`: `rescueWithSkip()` metodu
- `quiz.service.ts`: `failSession()` metodu
- `quiz.service.ts`: `completeSession()` response'una badge ekle
- `quiz.service.ts`: Power kullanımında `selected_answer` zorunluluğu kaldır
- `quiz.routes.ts`: `/rescue` ve `/fail` route'ları
- `quiz.controller.ts`: Yeni handler'lar
- `quiz.validator.ts`: Yeni schema'lar

### Flutter
- `quiz_screen.dart`: Tüm logic refactor (power, timer, feedback, rescue)
- `quiz_timer.dart`: addSeconds + pause/resume
- `answer_feedback_overlay.dart`: SKIP rescue kartı eklenmesi
- `power_bar.dart`: `_usePower()` callback değişikliği
- `quiz_provider.dart`: rescue/fail metodları, isLoading kaldırma
- `quiz_repository.dart`: Yeni API call'ları
- `quiz_service.dart` (retrofit): Yeni endpoint tanımları
- `quiz_model.dart`: Response'a badge eklenmesi
