# Soru Sonucu Ekranı İyileştirmesi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Soru çözme sonuç ekranındaki süre, yeşil elmas ve mor elmas hesaplama/gösterim buglarını düzeltmek ve detaylı istatistik kartları eklemek.

**Architecture:** Server tarafında usePower response'a cost/green_reward eklenir. Client tarafında mixin'de power kullanım kayıtları biriktirilir (extraTimeAdded, powerUsages listesi). Sonuç ekranında hibrit kartlarla toplam + detay gösterim yapılır.

**Tech Stack:** Flutter/Dart (Riverpod), Node.js/TypeScript (Express), Supabase PostgreSQL

---

## Dosya Haritası

| Dosya | Aksiyon | Sorumluluk |
|-------|---------|------------|
| `qulo-server/src/services/chat-question.service.ts` | Modify (satır 686) | usePower return'e cost + green_reward ekle |
| `qulov2/lib/data/models/chat_question_model.dart` | Modify | PowerUsageRecord sınıfı ekle |
| `qulov2/lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` | Modify | extraTimeAdded sayacı + powerUsages listesi |
| `qulov2/lib/features/chat/screens/solve_chat_question_screen.dart` | Modify (satır 51-55) | powerUsages parametresini result screen'e aktar |
| `qulov2/lib/features/chat/widgets/chat_question_result.dart` | Modify | Yeni hibrit kartlar (_GreenRewardDetailCard, _PurpleSpentCard) |

---

### Task 1: Server — usePower response'a cost ve green_reward ekle

**Files:**
- Modify: `qulo-server/src/services/chat-question.service.ts:686`

- [ ] **Step 1: usePower return objesine cost ve green_reward ekle**

`chat-question.service.ts` satır 686'yı değiştir:

```typescript
// ÖNCE (satır 686):
return { power_name: powerName, ...powerResult };

// SONRA:
return { power_name: powerName, cost, green_reward: greenReward, ...powerResult };
```

Bu değişiklik ORACLE, HALF, HINT, TIME_EXTEND power'ları için geçerli. SKIP ve POWER_UNBLOCK zaten kendi return bloklarında cost/green_reward dönüyor.

- [ ] **Step 2: Sunucuyu yeniden başlat ve doğrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
# Çalışan sunucuyu durdur
pkill -f "tsx.*src/index.ts" || true
# Yeniden başlat
npx tsx src/index.ts &
```

Beklenen: Sunucu hatasız başlar, `[server] Running on port 3001` görünür.

- [ ] **Step 3: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/services/chat-question.service.ts
git commit -m "fix: return cost and green_reward in usePower response for all powers"
```

---

### Task 2: Flutter Model — PowerUsageRecord sınıfı ekle

**Files:**
- Modify: `qulov2/lib/data/models/chat_question_model.dart`

- [ ] **Step 1: PowerUsageRecord sınıfını dosyanın sonuna ekle**

`chat_question_model.dart` dosyasının sonuna (satır 265'ten sonra) ekle:

```dart
class PowerUsageRecord {
  final String powerName;
  final int purpleSpent;
  final int greenEarned;

  const PowerUsageRecord({
    required this.powerName,
    required this.purpleSpent,
    required this.greenEarned,
  });
}
```

Bu sınıf JSON serialization gerektirmiyor — sadece client-side biriktirme için kullanılacak.

- [ ] **Step 2: flutter analyze çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
flutter analyze lib/data/models/chat_question_model.dart
```

Beklenen: Hata yok.

- [ ] **Step 3: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/data/models/chat_question_model.dart
git commit -m "feat: add PowerUsageRecord model for tracking power usage stats"
```

---

### Task 3: Mixin — extraTimeAdded ve powerUsages biriktirme

**Files:**
- Modify: `qulov2/lib/features/chat/mixins/solve_chat_question_screen_mixin.dart`

- [ ] **Step 1: Yeni state değişkenleri ekle**

Satır 32'den sonra (mevcut `ChatQuestionAnswerResponse? result;` altına) ekle:

```dart
  int _extraTimeAdded = 0;
  List<PowerUsageRecord> powerUsages = [];
```

- [ ] **Step 2: TIME_EXTEND case'inde extraTimeAdded sayacını artır**

Satır 127-128 civarındaki TIME_EXTEND case'ini değiştir:

```dart
// ÖNCE:
          case 'TIME_EXTEND':
            timerKey.currentState?.addSeconds(15);

// SONRA:
          case 'TIME_EXTEND':
            final extraSec = data.extraSeconds ?? 15;
            _extraTimeAdded += extraSec;
            timerKey.currentState?.addSeconds(extraSec);
```

- [ ] **Step 3: usePower success callback'inde powerUsages'a kayıt ekle**

`usePower` metodunda, `switch (powerName)` bloğundan ÖNCE (satır 113'ten önce, `ref.invalidate(exchangeProvider);` satırından sonra) power usage kaydını ekle:

```dart
        // Track power usage for result screen
        if (data.cost != null && data.cost! > 0) {
          powerUsages.add(PowerUsageRecord(
            powerName: powerName,
            purpleSpent: data.cost!,
            greenEarned: data.greenReward ?? 0,
          ));
        }
```

- [ ] **Step 4: submitAnswer'da timeSpent formulünü düzelt**

Satır 69-70'i değiştir:

```dart
// ÖNCE:
    final remaining = timerKey.currentState?.remainingSeconds ?? 0;
    final timeSpent = (startTime - remaining).clamp(0, startTime * 2);

// SONRA:
    final remaining = timerKey.currentState?.remainingSeconds ?? 0;
    final totalTime = startTime + _extraTimeAdded;
    final timeSpent = (totalTime - remaining).clamp(0, totalTime);
```

- [ ] **Step 5: submitAnswer success callback'inde answer reward'ı powerUsages'a ekle**

Satır 80-84 civarındaki success callback'i değiştir:

```dart
// ÖNCE:
      success: (response) {
        setState(() {
          answered = true;
          result = response;
        });
      },

// SONRA:
      success: (response) {
        // Track answer reward in power usages
        if (response.greenReward > 0) {
          powerUsages.add(PowerUsageRecord(
            powerName: 'ANSWER',
            purpleSpent: 0,
            greenEarned: response.greenReward,
          ));
        }
        setState(() {
          answered = true;
          result = response;
        });
      },
```

- [ ] **Step 6: SKIP via usePower'da da powerUsages'a kayıt ekle**

Mevcut SKIP case'inde (satır 129-139) power kaydı ekle. switch case'inin üstündeki genel powerUsages.add zaten cost>0 ise ekliyor, ama SKIP case'i `return;` ile erken çıkıyor. SKIP case'inin içine de answer reward ekle:

```dart
          case 'SKIP':
            // SKIP answer reward is already tracked by the generic block above (cost > 0)
            setState(() {
              answered = true;
              result = ChatQuestionAnswerResponse(
                isCorrect: true,
                unmatched: false,
                rewardMediaUrl: widget.question.rewardMediaUrl,
                greenReward: data.greenReward ?? 0,
                powersUsed: const ['SKIP'],
                correctOption: data.question?.answeredOption,
                answeredOption: data.question?.answeredOption,
              );
            });
            return;
```

- [ ] **Step 7: flutter analyze çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
flutter analyze lib/features/chat/mixins/solve_chat_question_screen_mixin.dart
```

Beklenen: Hata yok.

- [ ] **Step 8: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/features/chat/mixins/solve_chat_question_screen_mixin.dart
git commit -m "fix: correct time calculation with TIME_EXTEND and track power usage stats"
```

---

### Task 4: Solve Screen — powerUsages'ı result screen'e aktar

**Files:**
- Modify: `qulov2/lib/features/chat/screens/solve_chat_question_screen.dart:50-55`

- [ ] **Step 1: ChatQuestionResultScreen çağrısına powerUsages parametresini ekle**

Satır 50-55'i değiştir:

```dart
// ÖNCE:
    if (answered && result != null) {
      return ChatQuestionResultScreen(
        result: result!,
        question: widget.question,
        onRescue: !result!.isCorrect ? handleRescue : null,
      );
    }

// SONRA:
    if (answered && result != null) {
      return ChatQuestionResultScreen(
        result: result!,
        question: widget.question,
        onRescue: !result!.isCorrect ? handleRescue : null,
        powerUsages: powerUsages,
      );
    }
```

Bu adım Task 5 tamamlanana kadar compile hatası verecek — bir sonraki task'ta ChatQuestionResultScreen'e parametre eklenecek.

- [ ] **Step 2: Commit (Task 5 ile birlikte yapılacak)**

Bu adımın commit'i Task 5 ile birleştirilecek.

---

### Task 5: Sonuç Ekranı — Hibrit yeşil elmas ve mor elmas kartları

**Files:**
- Modify: `qulov2/lib/features/chat/widgets/chat_question_result.dart`

- [ ] **Step 1: ChatQuestionResultScreen'e powerUsages parametresi ekle**

Sınıf tanımını değiştir (satır 11-21):

```dart
class ChatQuestionResultScreen extends ConsumerWidget {
  final ChatQuestionAnswerResponse result;
  final ChatQuestionModel question;
  final VoidCallback? onRescue;
  final List<PowerUsageRecord> powerUsages;

  const ChatQuestionResultScreen({
    super.key,
    required this.result,
    required this.question,
    this.onRescue,
    this.powerUsages = const [],
  });
```

- [ ] **Step 2: Build metodunda mevcut _GreenRewardCard'ı yeni kartlarla değiştir**

Satır 97-103 civarını değiştir:

```dart
// ÖNCE:
                    if (result.greenReward > 0)
                      _GreenRewardCard(reward: result.greenReward),
                    if (result.powersUsed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _PowersUsedCard(powers: result.powersUsed),
                    ],

// SONRA:
                    if (_totalGreen > 0)
                      _GreenRewardDetailCard(
                        totalGreen: _totalGreen,
                        powerUsages: powerUsages,
                      ),
                    if (_totalPurple > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      _PurpleSpentCard(
                        totalPurple: _totalPurple,
                        powerUsages: powerUsages,
                      ),
                    ],
                    if (result.powersUsed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _PowersUsedCard(powers: result.powersUsed),
                    ],
```

- [ ] **Step 3: Helper getter'ları ekle**

`ChatQuestionResultScreen` sınıfına, `_hasRewardMedia` getter'ının yanına (satır 162) ekle:

```dart
  int get _totalGreen =>
      powerUsages.fold(0, (sum, p) => sum + p.greenEarned);

  int get _totalPurple =>
      powerUsages.fold(0, (sum, p) => sum + p.purpleSpent);
```

- [ ] **Step 4: _GreenRewardDetailCard widget'ını yaz**

Mevcut `_GreenRewardCard` sınıfının altına (satır 303'ten sonra) yeni widget ekle:

```dart
class _GreenRewardDetailCard extends StatefulWidget {
  final int totalGreen;
  final List<PowerUsageRecord> powerUsages;

  const _GreenRewardDetailCard({
    required this.totalGreen,
    required this.powerUsages,
  });

  @override
  State<_GreenRewardDetailCard> createState() => _GreenRewardDetailCardState();
}

class _GreenRewardDetailCardState extends State<_GreenRewardDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = context.appColors.success;

    // Group by powerName and sum greenEarned
    final grouped = <String, int>{};
    for (final usage in widget.powerUsages) {
      if (usage.greenEarned > 0) {
        grouped[usage.powerName] =
            (grouped[usage.powerName] ?? 0) + usage.greenEarned;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — tappable to expand
          GestureDetector(
            onTap: grouped.length > 1
                ? () => setState(() => _expanded = !_expanded)
                : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const DiamondIcon.green(size: 24, showGlow: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+${widget.totalGreen} Yeşil Elmas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Soru sahibine kazandırdın',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (grouped.length > 1)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.appColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
          // Expandable detail
          if (_expanded && grouped.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(
              color: successColor.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...grouped.entries.map((entry) {
              final label = entry.key == 'ANSWER'
                  ? 'Doğru cevap'
                  : entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    Text(
                      '+${entry.value}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: _PurpleSpentCard widget'ını yaz**

`_GreenRewardDetailCard`'ın altına ekle:

```dart
class _PurpleSpentCard extends StatefulWidget {
  final int totalPurple;
  final List<PowerUsageRecord> powerUsages;

  const _PurpleSpentCard({
    required this.totalPurple,
    required this.powerUsages,
  });

  @override
  State<_PurpleSpentCard> createState() => _PurpleSpentCardState();
}

class _PurpleSpentCardState extends State<_PurpleSpentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purpleColor = context.appColors.primary;

    // Group by powerName and sum purpleSpent
    final grouped = <String, int>{};
    for (final usage in widget.powerUsages) {
      if (usage.purpleSpent > 0) {
        grouped[usage.powerName] =
            (grouped[usage.powerName] ?? 0) + usage.purpleSpent;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: purpleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: purpleColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: grouped.length > 1
                ? () => setState(() => _expanded = !_expanded)
                : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const DiamondIcon.purple(size: 24, showGlow: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '-${widget.totalPurple} Mor Elmas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: purpleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Güç kullanımı için harcandı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (grouped.length > 1)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.appColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
          if (_expanded && grouped.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(
              color: purpleColor.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...grouped.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      Text(
                        '-${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: purpleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Import ekle**

Dosyanın başına `PowerUsageRecord` import'u ekle (zaten `chat_question_model.dart` import ediliyor, PowerUsageRecord aynı dosyada olduğu için ek import gerekmez).

- [ ] **Step 7: flutter analyze çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
flutter analyze lib/features/chat/
```

Beklenen: Hata yok.

- [ ] **Step 8: Commit (Task 4 ile birlikte)**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/features/chat/screens/solve_chat_question_screen.dart lib/features/chat/widgets/chat_question_result.dart
git commit -m "feat: add hybrid green/purple diamond detail cards to question result screen"
```

---

### Task 6: Son Doğrulama ve Temizlik

**Files:**
- Tüm değiştirilen dosyalar

- [ ] **Step 1: Tam flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
flutter analyze
```

Beklenen: Hata yok.

- [ ] **Step 2: Sunucunun çalıştığını doğrula**

```bash
curl -s http://localhost:3001/ping | head -1
```

Beklenen: `{"pong":true,...}`

- [ ] **Step 3: Mevcut _GreenRewardCard'ı kullanılmıyorsa kaldır**

`_GreenRewardCard` artık `_GreenRewardDetailCard` ile değiştirildi. Eğer başka bir yerde kullanılmıyorsa (grep ile kontrol et) sil:

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
grep -r "_GreenRewardCard" lib/
```

Eğer sadece tanım ve eski referans varsa → sınıfı sil. Eğer başka yerde kullanılıyorsa → bırak.

- [ ] **Step 4: Final commit (gerekirse)**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add -A
git commit -m "chore: remove unused _GreenRewardCard widget"
```
