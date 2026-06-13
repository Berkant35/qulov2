# Detaylı Cevap Sonucu Ekranı — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Soru cevabı sonrası ekranında yeşil elmas ödülü, kullanılan güçler ve cevap detaylarını göster

**Architecture:** Server `answerQuestion` response'una yeni alanlar eklenir, client model genişletilir, result ekranı kartlar halinde detayları gösterir.

**Tech Stack:** Node.js/Express (server), Flutter/Riverpod (client), json_serializable (codegen)

---

### Task 1: Server — AnswerQuestionResult Interface ve Return Değerleri

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/types/index.ts:85-91`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/services/chat-question.service.ts`

- [ ] **Step 1: AnswerQuestionResult interface'ini genişlet**

`/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/types/index.ts` — mevcut interface'i güncelle:

```typescript
export interface AnswerQuestionResult {
  question: ChatQuestionBase;
  is_correct: boolean;
  unmatched: boolean;
  skipped?: boolean;
  rescued?: boolean;
  green_reward?: number;
  powers_used?: string[];
  correct_option?: string;
  answered_option?: string;
  time_spent?: number | null;
}
```

- [ ] **Step 2: Normal cevap return'üne alanları ekle**

`/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/services/chat-question.service.ts` — `answerQuestion` metodunun normal cevap return'ü (satır ~417). `greenReward` değişkeni zaten `if (isCorrect)` bloğu içinde tanımlı, ama scope'u geniletmek lazım. `greenReward` değişkenini `isCorrect` kontrolünden ÖNCE 0 olarak tanımla ve `if (isCorrect)` içinde değerini ata.

Mevcut kodda (satır ~377-394):
```typescript
// Reward sender with green diamonds if correct (dynamic ratio)
if (isCorrect) {
  // Use a base reward of 10 for free questions
  const ecRewardConfig = await economyConfigService.getConfig();
  const greenReward = calculateGreenReward(10, ecRewardConfig.core.greenDiamondRewardRatio);
  if (greenReward > 0) {
    // ... earnGreen call
  }
}
```

Değiştir:
```typescript
// Reward sender with green diamonds if correct (dynamic ratio)
let greenReward = 0;
if (isCorrect) {
  const ecRewardConfig = await economyConfigService.getConfig();
  greenReward = calculateGreenReward(10, ecRewardConfig.core.greenDiamondRewardRatio);
  if (greenReward > 0) {
    try {
      await diamondService.earnGreen(
        question.sender_id,
        greenReward,
        "CHAT_QUESTION_REWARD",
        questionId,
      );
    } catch (err) {
      console.error("[chat-question] Diamond reward failed:", err);
    }
  }
}
```

Sonra return'ü güncelle (satır ~417):
```typescript
return {
  question: this.sanitizeQuestion(updated, userId),
  is_correct: isCorrect,
  unmatched,
  green_reward: greenReward,
  powers_used: question.powers_used ?? [],
  correct_option: question.correct_option,
  answered_option: selectedOption,
  time_spent: timeSpent ?? null,
};
```

- [ ] **Step 3: SKIP power return'üne alanları ekle**

Aynı dosyada, SKIP bloğunun return'ü (satır ~349):

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

- [ ] **Step 4: Rescue return'üne alanları ekle**

`rescueQuestion` metodunun return'ü (satır ~483):

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

- [ ] **Step 5: Server'ı derle ve test et**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npm run build
```

Sıfır hata olmalı.

- [ ] **Step 6: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && git add src/types/index.ts src/services/chat-question.service.ts && git commit -m "feat: add green_reward, powers_used, correct_option to answer response

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Client Model — ChatQuestionAnswerResponse Genişletme

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/models/chat_question_model.dart:96-117`
- Regenerate: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/models/chat_question_model.g.dart`

- [ ] **Step 1: ChatQuestionAnswerResponse'a yeni alanlar ekle**

`lib/data/models/chat_question_model.dart` — mevcut class'ı güncelle:

```dart
@JsonSerializable(createToJson: false)
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

  factory ChatQuestionAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionAnswerResponseFromJson(json);

  @override
  List<Object?> get props => [isCorrect, unmatched, rewardMediaUrl, greenReward, powersUsed, correctOption, answeredOption];
}
```

- [ ] **Step 2: build_runner çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

`chat_question_model.g.dart` yeniden oluşturulmalı.

- [ ] **Step 3: Mixin'deki hardcoded constructor'ları güncelle**

`lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — usePower SKIP case (satır ~131-138):

```dart
case 'SKIP':
  setState(() {
    answered = true;
    result = ChatQuestionAnswerResponse(
      isCorrect: true,
      unmatched: false,
      rewardMediaUrl: widget.question.rewardMediaUrl,
      powersUsed: const ['SKIP'],
    );
  });
  return;
```

submitGiveUp success (satır ~239-244):

```dart
success: (data) {
  setState(() {
    answered = true;
    result = ChatQuestionAnswerResponse(
      isCorrect: false,
      unmatched: false,
      correctOption: widget.question.correctOption,
    );
  });
},
```

Not: `ChatQuestionModel`'de `correctOption` alanının olup olmadığını kontrol et. Cevap verilmeden `correct_option` server tarafından gizleniyor, bu yüzden `null` olabilir. `submitGiveUp`'ta bu değer bilinmeyebilir — `null` bırak.

```dart
success: (data) {
  setState(() {
    answered = true;
    result = ChatQuestionAnswerResponse(
      isCorrect: false,
      unmatched: false,
    );
  });
},
```

- [ ] **Step 4: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && git add lib/data/models/chat_question_model.dart lib/data/models/chat_question_model.g.dart lib/features/chat/mixins/solve_chat_question_screen_mixin.dart && git commit -m "feat: extend ChatQuestionAnswerResponse with green_reward, powers_used, answer details

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Result Ekranı — Detay Kartları

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/chat/widgets/chat_question_result.dart`

- [ ] **Step 1: Import'ları ekle**

`lib/features/chat/widgets/chat_question_result.dart` dosyasının başına:

```dart
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
```

- [ ] **Step 2: build metoduna detay kartlarını ekle**

Mevcut `ChatQuestionResultScreen.build` metodunda, subtitle'dan sonra (satır ~88 `const SizedBox(height: AppSpacing.xxl)` öncesi), kartları ekle:

```dart
          // Subtitle
          if (result.unmatched)
            _UnmatchWarning()
          else if (isCorrect)
            Text(
              'Soruyu doğru cevapladın!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
          else ...[
            Text(
              'Bir dahaki sefere daha şanslı olursun.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRescue != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRescue,
                icon: Icon(Icons.skip_next, color: context.appColors.warning),
                label: Text(
                  'Kurtarma Hakkı (Skip)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.appColors.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          // ── Detail Cards ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              children: [
                if (result.greenReward > 0)
                  _GreenRewardCard(reward: result.greenReward),
                if (result.powersUsed.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _PowersUsedCard(powers: result.powersUsed),
                ],
                if (result.correctOption != null && result.answeredOption != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _AnswerDetailsCard(
                    answeredOption: result.answeredOption!,
                    correctOption: result.correctOption!,
                    isCorrect: result.isCorrect,
                    timeSpent: result.timeSpent,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Reward media reveal
```

`const Spacer(flex: 2)` ve `const Spacer(flex: 3)` yerlerini ayarla: Üstteki `Spacer(flex: 2)` → `Spacer(flex: 1)` yap ve alttaki `Spacer(flex: 3)` → `Spacer(flex: 1)` yap. Böylece detay kartlarına yer açılır. Veya Column'u `SingleChildScrollView` ile sar.

En temiz yaklaşım: `Column`'un tamamını `Expanded` + `SingleChildScrollView` ile sarmak — çok uzun içerik olursa scroll yapılabilsin. Mevcut `Spacer`'ları kaldır ve `body`'yi scroll yapılabilir yap.

- [ ] **Step 3: _GreenRewardCard widget'ını ekle**

Dosyanın sonuna:

```dart
class _GreenRewardCard extends StatelessWidget {
  final int reward;
  const _GreenRewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const DiamondIcon.green(size: 24, showGlow: false),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+$reward Yeşil Elmas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Soru sahibine kazandırdın',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: _PowersUsedCard widget'ını ekle**

```dart
class _PowersUsedCard extends StatelessWidget {
  final List<String> powers;
  const _PowersUsedCard({required this.powers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kullanılan Güçler',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: powers.map((name) {
              final type = PowerType.fromApiName(name);
              if (type == null) return const SizedBox.shrink();
              return Chip(
                avatar: PowerIcon(type: type, size: 16),
                label: Text(
                  name,
                  style: TextStyle(fontSize: 11, color: type.color),
                ),
                backgroundColor: type.color.withValues(alpha: 0.1),
                side: BorderSide(color: type.color.withValues(alpha: 0.3)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: _AnswerDetailsCard widget'ını ekle**

```dart
class _AnswerDetailsCard extends StatelessWidget {
  final String answeredOption;
  final String correctOption;
  final bool isCorrect;
  final int? timeSpent;

  const _AnswerDetailsCard({
    required this.answeredOption,
    required this.correctOption,
    required this.isCorrect,
    this.timeSpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctColor = context.appColors.success;
    final wrongColor = context.appColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: (isCorrect ? correctColor : wrongColor).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OptionBadge(
              label: 'Cevabın',
              option: answeredOption,
              color: isCorrect ? correctColor : wrongColor,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: theme.dividerColor,
          ),
          Expanded(
            child: _OptionBadge(
              label: 'Doğru',
              option: correctOption,
              color: correctColor,
            ),
          ),
          if (timeSpent != null) ...[
            Container(
              width: 1,
              height: 36,
              color: theme.dividerColor,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Süre',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${timeSpent}s',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionBadge extends StatelessWidget {
  final String label;
  final String option;
  final Color color;

  const _OptionBadge({
    required this.label,
    required this.option,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Body'yi scrollable yap**

`ChatQuestionResultScreen.build` metodunda, `body: Column(...)` yerine:

```dart
body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
    child: Column(
      children: [
        // Result icon
        _ResultIcon(isCorrect: isCorrect),
        const SizedBox(height: AppSpacing.xl),
        // ... tüm mevcut içerik (Spacer'lar kaldırılmış halde) ...
        // Back button
        const SizedBox(height: AppSpacing.xxl),
      ],
    ),
  ),
),
```

Mevcut `const Spacer(flex: 2)` ve `const Spacer(flex: 3)` satırlarını kaldır. `SingleChildScrollView` içinde `Spacer` çalışmaz.

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && git add lib/features/chat/widgets/chat_question_result.dart && git commit -m "feat: add green reward, powers used, answer details to result screen

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Entegrasyon Doğrulama

- [ ] **Step 1: Server build**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npm run build
```

- [ ] **Step 2: Flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/data/models/chat_question_model.dart lib/features/chat/widgets/chat_question_result.dart lib/features/chat/mixins/solve_chat_question_screen_mixin.dart
```

- [ ] **Step 3: Manuel test**

1. Bir sohbet aç → soruya doğru cevap ver
2. Result ekranında kontrol et: yeşil elmas kartı, cevap detayları, süre
3. Bir güç kullanıp cevap ver → kullanılan güçler kartı göründüğünü kontrol et
4. Yanlış cevap ver → kırmızı/yeşil renk ayrımını kontrol et
5. Kurtarma hakkı kullan → rescue sonrası detayların göründüğünü kontrol et
