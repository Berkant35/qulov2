# Soru Çözme Ekranı İyileştirmeleri — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Soru çözme ekranında 4 iyileştirme: tekrar çözme bug fix, güç envanteri badge, elmas bakiyesi, profil fotoğrafı

**Architecture:** Mevcut `SolveChatQuestionScreen` + mixin + body widget pattern'ine uyarak, route extra'yı `Map` yapısına çevirip `matchId` geçişi sağlayacağız. Provider'lar (`exchangeProvider`, `diamondProvider`, `matchListProvider`) ekranın `build` metodunda watch edilecek.

**Tech Stack:** Flutter, Riverpod, GoRouter, CachedNetworkImage

---

### Task 1: Tekrar Çözme Bug Fix — Route ve Cache Guard

**Files:**
- Modify: `lib/routing/app_routes.dart:169-191`
- Modify: `lib/features/chat/screens/solve_chat_question_screen.dart`
- Modify: `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart:34-36`
- Modify: `lib/features/chat/widgets/chat_question_message.dart:26-54`

- [ ] **Step 1: Route extra'yı Map yapısına çevir**

`lib/routing/app_routes.dart` satır 169-191 arasındaki route tanımını güncelle:

```dart
// Solve Chat Question (root navigator — full screen over bottom nav)
GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  path: '/chat-question/:questionId/solve',
  name: RouteNames.solveChatQuestion,
  pageBuilder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return CustomTransitionPage(
      key: state.pageKey,
      child: SolveChatQuestionScreen(
        question: extra['question'] as ChatQuestionModel,
        matchId: extra['matchId'] as String,
      ),
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  },
),
```

- [ ] **Step 2: SolveChatQuestionScreen'e matchId parametresi ekle**

`lib/features/chat/screens/solve_chat_question_screen.dart` — constructor'a `matchId` ekle:

```dart
class SolveChatQuestionScreen extends ConsumerStatefulWidget {
  final ChatQuestionModel question;
  final String matchId;

  const SolveChatQuestionScreen({
    super.key,
    required this.question,
    required this.matchId,
  });

  @override
  ConsumerState<SolveChatQuestionScreen> createState() =>
      _SolveChatQuestionScreenState();
}
```

- [ ] **Step 3: Mixin'e isAnswered guard ekle**

`lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — `initMixin()` metodunu güncelle:

```dart
void initMixin() {
  powerBlockActive = widget.question.isPowerBlocked;

  // Guard: zaten cevaplanmış soruyu tekrar açma
  if (widget.question.isAnswered) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }
}
```

- [ ] **Step 4: Cevaplama sonrası pop'a sonuç ekle**

`lib/features/chat/screens/solve_chat_question_screen.dart` — close butonuna ve result ekranına `pop(answered)` ekle:

```dart
@override
Widget build(BuildContext context) {
  if (answered && result != null) {
    return ChatQuestionResultScreen(
      result: result!,
      question: widget.question,
      onRescue: !result!.isCorrect ? handleRescue : null,
      onClose: () => Navigator.of(context).pop(true),
    );
  }

  final q = widget.question;

  return PopScope(
    canPop: false,
    child: AppScaffold(
      title: q.questionText.length > 25
          ? '${q.questionText.substring(0, 25)}...'
          : q.questionText,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(false),
      ),
      padding: EdgeInsets.zero,
      body: SolveQuestionBody(/* ... mevcut parametreler ... */),
    ),
  );
}
```

Not: `ChatQuestionResultScreen`'in `onClose` callback'i yoksa ekle. Eğer kendi içinde pop yapıyorsa, onun pop çağrısını `Navigator.of(context).pop(true)` olarak güncelle.

- [ ] **Step 5: ChatQuestionMessage — navigation'a matchId ekle + pop sonucunu handle et**

`lib/features/chat/widgets/chat_question_message.dart` — `_openSolveScreen` metodunu güncelle:

```dart
Future<void> _openSolveScreen(
  BuildContext context,
  WidgetRef ref,
  ChatQuestionModel question,
) async {
  final wasAnswered = await ref.read(navigationServiceProvider).push<bool>(
    RouteNames.solveChatQuestion,
    params: {'questionId': question.id},
    extra: {'question': question, 'matchId': matchId},
  );

  if (!context.mounted) return;

  if (wasAnswered == true) {
    // Anında cache'i güncelle — kart "cevaplanmış" state'e geçer
    ref.read(chatQuestionCacheProvider.notifier).update((state) {
      final updated = Map<String, ChatQuestionModel>.from(state);
      updated.remove(questionId);
      return updated;
    });
    ref.invalidate(chatQuestionFetchProvider(questionId));
  }
}
```

- [ ] **Step 6: `ChatQuestionResultScreen`'in pop davranışını kontrol et**

`lib/features/chat/widgets/chat_question_result.dart` dosyasını oku. Eğer close/back butonuna basınca doğrudan `Navigator.of(context).pop()` çağırıyorsa, `Navigator.of(context).pop(true)` olarak güncelle. Ya da `onClose` callback ekleyerek parent'tan kontrol sağla.

- [ ] **Step 7: Commit**

```bash
git add lib/routing/app_routes.dart lib/features/chat/screens/solve_chat_question_screen.dart lib/features/chat/mixins/solve_chat_question_screen_mixin.dart lib/features/chat/widgets/chat_question_message.dart lib/features/chat/widgets/chat_question_result.dart
git commit -m "fix: prevent re-solving answered chat questions + pass matchId via route"
```

---

### Task 2: Güç Envanteri Badge — Power Bar'a Envanter Sayısı Ekleme

**Files:**
- Modify: `lib/features/chat/widgets/chat_question_power_bar.dart`
- Modify: `lib/features/chat/widgets/solve_question_body.dart`
- Modify: `lib/features/chat/screens/solve_chat_question_screen.dart`
- Modify: `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart`

- [ ] **Step 1: ChatQuestionPowerBar'a powerCounts parametresi ekle**

`lib/features/chat/widgets/chat_question_power_bar.dart` — sınıfa parametre ekle:

```dart
class ChatQuestionPowerBar extends StatelessWidget {
  final int optionCount;
  final bool isPowerBlocked;
  final bool hasHint;
  final Future<void> Function(String powerName) onPowerTap;
  final Set<String> disabledPowers;
  final Map<String, int> powerCounts;

  const ChatQuestionPowerBar({
    super.key,
    required this.optionCount,
    required this.isPowerBlocked,
    required this.hasHint,
    required this.onPowerTap,
    this.disabledPowers = const {},
    this.powerCounts = const {},
  });
```

Build metodunda `_ChatPowerButton`'a `count` geç:

```dart
return _ChatPowerButton(
  type: type,
  isUsed: isUsed,
  count: powerCounts[type.apiName] ?? 0,
  onTap: isUsed
      ? null
      : () async => onPowerTap(type.apiName),
);
```

- [ ] **Step 2: _ChatPowerButton'a badge ekle**

`lib/features/chat/widgets/chat_question_power_bar.dart` — `_ChatPowerButton` sınıfını güncelle:

```dart
class _ChatPowerButton extends StatelessWidget {
  final PowerType type;
  final bool isUsed;
  final int count;
  final Future<void> Function()? onTap;

  const _ChatPowerButton({
    required this.type,
    required this.isUsed,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    final hasInventory = count > 0;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
        child: Opacity(
          opacity: isUsed ? 1.0 : (hasInventory ? 1.0 : 0.4),
          child: SizedBox(
            width: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUsed
                            ? context.appColors.surfaceElevated
                            : color.withValues(alpha: 0.15),
                        border: Border.all(
                          color: isUsed
                              ? Colors.grey.withValues(alpha: 0.3)
                              : color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isLoading
                            ? const AppLoadingWidget.small()
                            : isUsed
                                ? Icon(Icons.check, size: 20, color: Colors.grey)
                                : QIcon(
                                    type.iconPath,
                                    size: 22,
                                    color: color,
                                  ),
                      ),
                    ),
                    if (!isUsed && hasInventory)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _powerLabel(type),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isUsed ? Colors.grey : color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 3: SolveQuestionBody'ye powerCounts parametresi ekle**

`lib/features/chat/widgets/solve_question_body.dart` — sınıfa parametre ekle ve `ChatQuestionPowerBar`'a geç:

```dart
class SolveQuestionBody extends StatelessWidget {
  // ... mevcut parametreler ...
  final Map<String, int> powerCounts;

  const SolveQuestionBody({
    // ... mevcut parametreler ...
    required this.onPowerTap,
    this.powerCounts = const {},
  });
```

Build metodunda `ChatQuestionPowerBar`'a geç:

```dart
ChatQuestionPowerBar(
  optionCount: question.optionCount,
  isPowerBlocked: powerBlockActive,
  hasHint: question.hintText != null && question.hintText!.isNotEmpty,
  onPowerTap: onPowerTap,
  powerCounts: powerCounts,
  disabledPowers: {
    if (suggestedOption != null) 'ORACLE',
    if (removedOptions.isNotEmpty) 'HALF',
    if (hintVisible) 'HINT',
  },
),
```

- [ ] **Step 4: Mixin'de exchangeProvider fetch et**

`lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — `initMixin()` içine ekle:

```dart
import 'package:qulo_v2/providers/exchange_provider.dart';
```

```dart
void initMixin() {
  powerBlockActive = widget.question.isPowerBlocked;

  if (widget.question.isAnswered) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
    return;
  }

  // Envanter verisi yoksa fetch et
  final exchange = ref.read(exchangeProvider);
  if (exchange.inventory.isEmpty) {
    ref.read(exchangeProvider.notifier).fetchAll();
  }
}
```

- [ ] **Step 5: SolveChatQuestionScreen build'inde exchangeProvider watch et ve body'ye geç**

`lib/features/chat/screens/solve_chat_question_screen.dart` — build metodunda:

```dart
import 'package:qulo_v2/providers/exchange_provider.dart';

// build() içinde, body oluşturmadan önce:
final exchange = ref.watch(exchangeProvider);
final powerCounts = <String, int>{};
for (final type in PowerType.values) {
  final c = exchange.getCount(type.apiName);
  if (c > 0) powerCounts[type.apiName] = c;
}
```

Sonra `SolveQuestionBody`'ye ekle:

```dart
body: SolveQuestionBody(
  // ... mevcut parametreler ...
  onPowerTap: usePower,
  powerCounts: powerCounts,
),
```

`import 'package:qulo_v2/core/widgets/power_icon.dart';` importu da eklenmeli (PowerType için).

- [ ] **Step 6: Güç kullanımı sonrası envanteri invalidate et**

`lib/features/chat/mixins/solve_chat_question_screen_mixin.dart` — `usePower` success bloğuna ekle:

```dart
success: (data) {
  ref.invalidate(diamondProvider);
  ref.invalidate(exchangeProvider); // Envanter güncelle
  // ... mevcut switch-case ...
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/widgets/chat_question_power_bar.dart lib/features/chat/widgets/solve_question_body.dart lib/features/chat/screens/solve_chat_question_screen.dart lib/features/chat/mixins/solve_chat_question_screen_mixin.dart
git commit -m "feat: show power inventory badges on chat question power bar"
```

---

### Task 3: Elmas Bakiyesi — AppBar'da Kompakt Gösterim

**Files:**
- Modify: `lib/features/chat/screens/solve_chat_question_screen.dart`

- [ ] **Step 1: _CompactDiamondBalance widget'ı ekle**

`lib/features/chat/screens/solve_chat_question_screen.dart` dosyasının sonuna (class dışına) ekle:

```dart
class _CompactDiamondBalance extends StatelessWidget {
  final int purple;
  final int green;

  const _CompactDiamondBalance({
    required this.purple,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DiamondIcon.purple(size: 14, showGlow: false),
          const SizedBox(width: 2),
          Text(
            '$purple',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.sm),
          const DiamondIcon.green(size: 14, showGlow: false),
          const SizedBox(width: 2),
          Text(
            '$green',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

Import ekle:
```dart
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
```

- [ ] **Step 2: AppBar actions'a diamond balance ekle**

`lib/features/chat/screens/solve_chat_question_screen.dart` — build metodunda `diamondProvider` watch et ve `AppScaffold`'a `actions` ekle:

```dart
final diamonds = ref.watch(diamondProvider);
final balance = diamonds.valueOrNull;
```

AppScaffold'a actions ekle:

```dart
return PopScope(
  canPop: false,
  child: AppScaffold(
    title: q.questionText.length > 25
        ? '${q.questionText.substring(0, 25)}...'
        : q.questionText,
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(false),
    ),
    actions: [
      if (balance != null)
        _CompactDiamondBalance(
          purple: balance.purple,
          green: balance.green,
        ),
    ],
    padding: EdgeInsets.zero,
    body: SolveQuestionBody(/* ... */),
  ),
);
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/screens/solve_chat_question_screen.dart
git commit -m "feat: show diamond balance in chat question solve screen appbar"
```

---

### Task 4: Karşı Kişinin Profil Fotoğrafı

**Files:**
- Modify: `lib/features/chat/widgets/solve_question_body.dart`
- Modify: `lib/features/chat/screens/solve_chat_question_screen.dart`

- [ ] **Step 1: SolveQuestionBody'ye sender bilgisi parametreleri ekle**

`lib/features/chat/widgets/solve_question_body.dart` — sınıfa parametreler ekle:

```dart
class SolveQuestionBody extends StatelessWidget {
  // ... mevcut parametreler ...
  final Map<String, int> powerCounts;
  final String? senderPhotoUrl;
  final String? senderName;

  const SolveQuestionBody({
    // ... mevcut parametreler ...
    this.powerCounts = const {},
    this.senderPhotoUrl,
    this.senderName,
  });
```

- [ ] **Step 2: Profil fotoğrafı widget'ını build'e ekle**

`lib/features/chat/widgets/solve_question_body.dart` — build metodunda timer'dan önce ekle:

Import ekle:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

Build metodunda `QuizTimer`'dan önce:

```dart
return Padding(
  padding: const EdgeInsets.all(AppSpacing.pagePadding),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // ── Sender info ──
      if (senderName != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.appColors.surfaceElevated,
                backgroundImage: senderPhotoUrl != null
                    ? CachedNetworkImageProvider(senderPhotoUrl!)
                    : null,
                child: senderPhotoUrl == null
                    ? Icon(Icons.person, size: 20, color: context.appColors.textSecondary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                senderName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      // ── Timer ──
      QuizTimer(
```

- [ ] **Step 3: SolveChatQuestionScreen'de match user bilgisi al ve body'ye geç**

`lib/features/chat/screens/solve_chat_question_screen.dart` — build metodunda:

```dart
import 'package:qulo_v2/providers/match_provider.dart';
```

Build metodu içinde (body oluşturmadan önce):

```dart
// Match user bilgisi
final matchUser = ref.watch(matchListProvider).whenData((matches) {
  try {
    return matches.firstWhere((m) => m.matchId == widget.matchId).user;
  } catch (_) {
    return null;
  }
}).valueOrNull;

final senderPhotoUrl = matchUser?.photos?.isNotEmpty == true
    ? matchUser!.photos!.first
    : null;
final senderName = matchUser?.name;
```

`SolveQuestionBody`'ye geç:

```dart
body: SolveQuestionBody(
  // ... mevcut parametreler ...
  powerCounts: powerCounts,
  senderPhotoUrl: senderPhotoUrl,
  senderName: senderName,
),
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/widgets/solve_question_body.dart lib/features/chat/screens/solve_chat_question_screen.dart
git commit -m "feat: show sender profile photo on chat question solve screen"
```

---

### Task 5: Entegrasyon Doğrulama

**Files:** Tüm değişen dosyalar

- [ ] **Step 1: Flutter analyze çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze
```

Sıfır hata olmalı.

- [ ] **Step 2: Tüm import'ları kontrol et**

`solve_chat_question_screen.dart` dosyasının final import listesi:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_result.dart';
import 'package:qulo_v2/features/chat/widgets/solve_question_body.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
```

- [ ] **Step 3: Hot restart + manuel test**

1. Bir sohbet aç → karşıdaki kişinin sorusuna tıkla
2. Kontrol et: Profil fotoğrafı + isim görünüyor
3. Kontrol et: AppBar'da elmas bakiyesi görünüyor
4. Kontrol et: Power bar'da envanter badge'leri görünüyor
5. Soruyu cevapla → geri çık → tekrar tıkla → sorunun "cevaplanmış" state'te olduğunu kontrol et
6. Bir güç kullan → envanter badge sayısının düştüğünü kontrol et
7. Bir güç kullan → elmas bakiyesinin güncellendiğini kontrol et

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "test: verify solve screen improvements integration"
```
