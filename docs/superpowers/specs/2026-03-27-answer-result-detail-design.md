# Detaylı Cevap Sonucu Ekranı

**Tarih:** 2026-03-27
**Kapsam:** Server answerQuestion response + Client ChatQuestionResultScreen

## 1. Server — Response Zenginleştirme

### AnswerQuestionResult interface genişletme

`qulo-server/src/types/index.ts` — mevcut interface'e eklenen alanlar:

| Alan | Tip | Açıklama |
|------|-----|----------|
| `green_reward` | `number` | Soru sahibine kazandırılan yeşil elmas (0 ise kazanılmadı) |
| `powers_used` | `string[]` | Bu soruda kullanılan güçler listesi |
| `correct_option` | `string` | Doğru cevap (A/B/C/D) |
| `answered_option` | `string` | Verilen cevap |
| `time_spent` | `number \| null` | Harcanan süre (saniye) |

### answerQuestion return değerleri güncelleme

`qulo-server/src/services/chat-question.service.ts` — Her return bloğuna yeni alanlar eklenir:

**Normal cevap (satır ~417):**
```typescript
return {
  question: this.sanitizeQuestion(updated, userId),
  is_correct: isCorrect,
  unmatched,
  green_reward: isCorrect ? greenReward : 0,
  powers_used: question.powers_used ?? [],
  correct_option: question.correct_option,
  answered_option: selectedOption,
  time_spent: timeSpent ?? null,
};
```

**SKIP power cevap (satır ~349):**
```typescript
return {
  question: this.sanitizeQuestion(updated, userId),
  is_correct: true,
  unmatched: false,
  skipped: true,
  green_reward: greenReward,
  powers_used: [...(question.powers_used ?? []), "SKIP"],
  correct_option: question.correct_option,
  answered_option: question.correct_option,
  time_spent: timeSpent ?? null,
};
```

**Rescue (satır ~483):**
```typescript
return {
  question: this.sanitizeQuestion(updated, userId),
  is_correct: true,
  unmatched: false,
  rescued: true,
  green_reward: greenReward,
  powers_used: [...(question.powers_used ?? []), "SKIP_RESCUE"],
  correct_option: question.correct_option,
  answered_option: question.correct_option,
  time_spent: null,
};
```

### sanitizeQuestion güncelleme

`correct_option` artık cevap sonrası response'ta ayrı alan olarak döndüğü için, `sanitizeQuestion` metodunun `correct_option`'ı gizleme davranışı cevap sonrası response'u etkilemez (zaten ayrı bir top-level alan).

---

## 2. Client Model Güncelleme

### ChatQuestionAnswerResponse genişletme

`lib/data/models/chat_question_model.dart`:

```dart
class ChatQuestionAnswerResponse extends Equatable {
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  final bool unmatched;
  @JsonKey(name: 'reward_media_url')
  final String? rewardMediaUrl;
  final ChatQuestionModel? question;
  @JsonKey(name: 'green_reward')
  final int greenReward;
  @JsonKey(name: 'powers_used')
  final List<String> powersUsed;
  @JsonKey(name: 'correct_option')
  final String? correctOption;
  @JsonKey(name: 'answered_option')
  final String? answeredOption;
  @JsonKey(name: 'time_spent')
  final int? timeSpent;

  const ChatQuestionAnswerResponse({
    required this.isCorrect,
    required this.unmatched,
    this.rewardMediaUrl,
    this.question,
    this.greenReward = 0,
    this.powersUsed = const [],
    this.correctOption,
    this.answeredOption,
    this.timeSpent,
  });
}
```

`build_runner` çalıştırılarak `.g.dart` dosyası yeniden oluşturulacak.

---

## 3. Result Ekranı — Detaylı Gösterim

### Layout

```
      [Animasyonlu ikon — ✅ veya ❌]

      "Tebrikler!" / "Yanlış Cevap"
      "Soruyu doğru cevapladın!" / "Bir dahaki sefere..."

  ┌─────────────────────────────┐
  │  💚 +3 Yeşil Elmas          │  ← greenReward > 0 ise
  │  Soru sahibine kazandırdın   │
  └─────────────────────────────┘

  ┌─────────────────────────────┐
  │  ⚡ Kullanılan Güçler        │  ← powersUsed.isNotEmpty ise
  │  [Oracle] [Half] [Skip]     │     PowerIcon widget'ları ile
  └─────────────────────────────┘

  ┌─────────────────────────────┐
  │  📊 Detaylar                 │
  │  Cevabın: B    Doğru: B     │  ← Doğruysa yeşil, yanlışsa kırmızı/yeşil
  │  Süre: 12s                  │
  └─────────────────────────────┘

  [Reward Media — fotoğraf/ses]   ← Varsa (mevcut davranış)
  [Kurtarma Hakkı butonu]        ← Yanlış cevap + onRescue varsa

  [         Geri Dön            ]
```

### Widget'lar

Tüm kartlar (`_GreenRewardCard`, `_PowersUsedCard`, `_AnswerDetailsCard`) `chat_question_result.dart` içinde private widget olarak tanımlanır.

**_GreenRewardCard:**
- `DiamondIcon.green(size: 24)` + "+N" text + açıklama
- Yeşil tonlarda container, border
- Sadece `greenReward > 0` ise render edilir

**_PowersUsedCard:**
- `PowerType.fromApiName(name)` ile her güç için ikon
- `Wrap` layout ile güç ikonları yan yana
- Sadece `powersUsed.isNotEmpty` ise render edilir

**_AnswerDetailsCard:**
- Verilen cevap ve doğru cevap yan yana
- Doğruysa her ikisi yeşil, yanlışsa verilen kırmızı + doğru yeşil
- Süre bilgisi (timeSpent saniye)
- Her zaman render edilir (correctOption ve answeredOption null değilse)

### Mevcut davranış korunacaklar
- Animasyonlu ikon (mevcut `_ResultIcon`)
- Unmatch uyarısı (mevcut `_UnmatchWarning`)
- Reward media reveal (mevcut `RewardMediaReveal`)
- Kurtarma hakkı butonu (mevcut `onRescue`)
- Geri dön butonu + `pop(true)`

---

## Etkilenen Dosyalar

### Server
- `qulo-server/src/types/index.ts` — AnswerQuestionResult interface
- `qulo-server/src/services/chat-question.service.ts` — return değerleri

### Client
- `lib/data/models/chat_question_model.dart` — ChatQuestionAnswerResponse
- `lib/data/models/chat_question_model.g.dart` — build_runner regenerate
- `lib/features/chat/widgets/chat_question_result.dart` — UI güncellemesi
- `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — submitWithSkip ve submitGiveUp'taki hardcoded ChatQuestionAnswerResponse constructor'ları güncellenmeli

## Kapsam Dışı
- Chat ekranında toplam kazanılan yeşil elmas özeti (ayrı feature)
- Cevap sonrası animasyonlar (confetti vb.)
- Paylaşım özelliği
