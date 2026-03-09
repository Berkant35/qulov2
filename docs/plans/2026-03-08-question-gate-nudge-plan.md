# Question Gate & Nudge System — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Sorusu < 2 olan kullanıcıları discover'dan filtrele ve uygulama genelinde gamified nudge'lar ekleyerek soru oluşturmayı teşvik et.

**Architecture:** Backend'de discover query'sine question count filtresi + /me'ye question_count alanı eklenir. Flutter'da UserModel'e questionCount eklenir, tüm nudge widget'ları bu tek kaynaktan beslenir. Ortak widget'lar lib/core/widgets/'a yazılır.

**Tech Stack:** Node.js/Express (backend), Flutter/Riverpod (mobile), Supabase PostgreSQL

---

### Task 1: Backend — /me'ye question_count ekle

**Files:**
- Modify: `server/src/services/user.service.ts:7-36`

**Step 1: getMe()'ye question count sorgusu ekle**

`user.service.ts`'in `getMe()` metodunda, user_details fetch'inden sonra question count sorgusu ekle:

```typescript
// user.service.ts → getMe() — details fetch'inden sonra, return'den önce ekle:

    // Fetch question count
    const { count: questionCount } = await supabase
      .from("questions")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId);
```

Return objesine ekle:

```typescript
    return {
      ...user,
      question_count: questionCount ?? 0,  // ← yeni alan
      subscriptionPlan: user.subscription_plan || null,
      // ... mevcut alanlar
    };
```

**Step 2: Commit**

```bash
git add server/src/services/user.service.ts
git commit -m "feat: add question_count to /me endpoint"
```

---

### Task 2: Backend — Discover'dan sorusuz kullanıcıları filtrele

**Files:**
- Modify: `server/src/services/matching.service.ts:150-175`

**Step 1: Question count filtresini ekle**

`matching.service.ts`'in `discover()` metodunda, batch question count fetch'inden sonra (satır ~148), scored array'i oluşturmadan önce filtreleme ekle:

```typescript
    // 5.5 — Filter out users with < 2 questions (not discoverable)
    const discoverableFiltered = filtered.filter((c) => {
      const qCount = questionCountMap.get(c.id) ?? 0;
      return qCount >= 2;
    });
```

Sonra `scored` map'inde `filtered` yerine `discoverableFiltered` kullan:

```typescript
    const scored = discoverableFiltered.map((c) => {
      // ... mevcut scoring kodu
    });
```

**Step 2: Commit**

```bash
git add server/src/services/matching.service.ts
git commit -m "feat: filter users with < 2 questions from discover"
```

---

### Task 3: Flutter — UserModel'e questionCount ekle

**Files:**
- Modify: `lib/data/models/user_model.dart`
- Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 1: UserModel'e questionCount alanı ekle**

`user_model.dart`'ta `badgeRewardsClaimed` alanından sonra ekle:

```dart
  @JsonKey(name: 'question_count', defaultValue: 0)
  final int questionCount;
```

Constructor'a ekle (details'ten önce):

```dart
    this.questionCount = 0,
```

Props'a ekle:

```dart
  @override
  List<Object?> get props => [id, questionCount];
```

**Step 2: build_runner çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/models/user_model.dart lib/data/models/user_model.g.dart
git commit -m "feat: add questionCount field to UserModel"
```

---

### Task 4: Flutter — i18n anahtarları ekle

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: TR ve EN map'lerine nudge anahtarlarını ekle**

`_tr` map'ine (mevcut question anahtarlarının yanına) ekle:

```dart
    // Question Gate & Nudge
    'question_nudge_title': 'Keşfedilmek için sorularını ekle!',
    'question_nudge_subtitle': 'Profilin %{percent} hazır — sadece sorular eksik!',
    'question_nudge_progress': '{count}/2 soru',
    'question_nudge_add_button': 'Sorularımı Ekle',
    'question_nudge_edit_hint': 'Profilini düzenlemek harika! Eşleşmelerde görünmek için en az 2 soru eklemeyi unutma.',
    'question_nudge_go_questions': 'Sorularıma Git',
    'question_nudge_discover_locked': 'Sorularını ekle, keşfetmeye başla!',
    'question_nudge_celebration_title': 'Tebrikler! Artık keşfedilebilirsin!',
    'question_nudge_celebration_button': 'Keşfetmeye Başla',
    'question_nudge_menu_required': '2 soru gerekli',
```

`_en` map'ine ekle:

```dart
    // Question Gate & Nudge
    'question_nudge_title': 'Add questions to be discovered!',
    'question_nudge_subtitle': 'Your profile is %{percent} ready — just questions missing!',
    'question_nudge_progress': '{count}/2 questions',
    'question_nudge_add_button': 'Add My Questions',
    'question_nudge_edit_hint': 'Great job editing your profile! Don\'t forget to add at least 2 questions to appear in matches.',
    'question_nudge_go_questions': 'Go to My Questions',
    'question_nudge_discover_locked': 'Add your questions to start discovering!',
    'question_nudge_celebration_title': 'Congratulations! You\'re now discoverable!',
    'question_nudge_celebration_button': 'Start Discovering',
    'question_nudge_menu_required': '2 questions required',
```

**Step 2: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add question gate nudge i18n keys (TR + EN)"
```

---

### Task 5: Flutter — QuestionGateBanner ortak widget'ı

**Files:**
- Create: `lib/core/widgets/question_gate_banner.dart`

**Step 1: Ortak banner widget'ı oluştur**

Bu widget profil ve edit profil ekranlarında kullanılacak. Gradient arka plan, kilit ikonu, progress bar ve CTA butonu içerir.

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class QuestionGateBanner extends StatelessWidget {
  final int questionCount;
  final int profileCompletion;
  final VoidCallback onAddQuestions;

  const QuestionGateBanner({
    super.key,
    required this.questionCount,
    required this.profileCompletion,
    required this.onAddQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = questionCount / 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(30),
            AppColors.secondary.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QIcon(QIcons.icLock, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('question_nudge_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('question_nudge_subtitle')
                .replaceAll('%{percent}', '$profileCompletion'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('question_nudge_progress')
                .replaceAll('{count}', '$questionCount'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddQuestions,
              icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onPrimary, size: 18),
              label: Text(context.tr('question_nudge_add_button')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/widgets/question_gate_banner.dart
git commit -m "feat: add QuestionGateBanner shared widget"
```

---

### Task 6: Flutter — Profil ekranına banner + menu badge ekle

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Import ekle**

```dart
import 'package:qulo_v2/core/widgets/question_gate_banner.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
```

**Step 2: Photo grid'den sonra, name/age'den önce banner ekle**

`profile_screen.dart`'ta `PhotoGridFull` widget'ından sonra (satır ~74), `const SizedBox(height: AppSpacing.lg)` ve name/age Text'inden önce ekle:

```dart
                // ─── Question Gate Banner ───
                if (user.questionCount < AppConstants.minQuestions) ...[
                  const SizedBox(height: AppSpacing.md),
                  QuestionGateBanner(
                    questionCount: user.questionCount,
                    profileCompletion: user.profileCompletion,
                    onAddQuestions: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                  ),
                ],
```

**Step 3: _MenuItem'ı "Sorularım" için güncelle**

Mevcut "Sorularım" `_MenuItem`'ını (satır ~181-184) subtitle ve badge destekli versiyona çevir:

```dart
                _MenuItem(
                  iconPath: QIcons.icHelpCircle,
                  title: context.tr('my_questions'),
                  subtitle: user.questionCount < AppConstants.minQuestions
                      ? context.tr('question_nudge_menu_required')
                      : null,
                  showBadge: user.questionCount < AppConstants.minQuestions,
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                ),
```

**Step 4: _MenuItem widget'ına subtitle ve badge desteği ekle**

`_MenuItem` class'ına yeni parametreler ekle:

```dart
class _MenuItem extends StatelessWidget {
  final String? iconPath;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final bool showBadge;
  final VoidCallback onTap;

  const _MenuItem({
    this.iconPath,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.showBadge = false,
    required this.onTap,
  }) : assert(iconPath != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget ?? QIcon(iconPath!, color: AppColors.primary, size: 24),
            if (showBadge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error))
            : null,
        trailing: QIcon(QIcons.icChevronRight, color: theme.hintColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
```

**Step 5: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: add question gate banner and menu badge to profile screen"
```

---

### Task 7: Flutter — Edit profil ekranına info banner ekle

**Files:**
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`

**Step 1: Import ekle**

```dart
import 'package:qulo_v2/core/constants/app_constants.dart';
```

**Step 2: Photos section'dan önce info banner ekle**

`edit_profile_screen.dart`'ın `Column` children'ında, photos section'dan önce (satır ~309) ekle:

```dart
            // ─── Question Nudge Banner ───
            Builder(builder: (_) {
              final user = ref.watch(userProvider).valueOrNull;
              if (user == null || user.questionCount >= AppConstants.minQuestions) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('question_nudge_edit_hint'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                        child: Text(context.tr('question_nudge_go_questions')),
                      ),
                    ],
                  ),
                ),
              );
            }),
```

**Step 3: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart
git commit -m "feat: add question nudge info banner to edit profile screen"
```

---

### Task 8: Flutter — Discover ekranına bulanık kilit overlay'i ekle

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`

**Step 1: Import ekle**

```dart
import 'dart:ui';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
```

**Step 2: data callback'te kartlar gösterilmeden önce kilit kontrolü ekle**

`discover_screen.dart`'ın `data:` callback'inde, mevcut `discover.cards.isEmpty` kontrolünden sonra, `final card = discover.cards.first;` satırından önce yeni bir kontrol ekle.

Mevcut `data:` callback'ini şu şekilde güncelle — `final card = discover.cards.first;` satırından önce ekle:

```dart
          // ─── Question Gate: Blur Lock ───
          final user = ref.watch(userProvider).valueOrNull;
          final hasMinQuestions = (user?.questionCount ?? 0) >= AppConstants.minQuestions;

          if (!hasMinQuestions) {
            final card = discover.cards.isNotEmpty ? discover.cards.first : null;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Stack(
                children: [
                  // Blurred card (show first card if available, or placeholder)
                  if (card != null)
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: ProfileCard(card: card),
                      ),
                    )
                  else
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  // Lock overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(180),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          QIcon(QIcons.icLock, size: 64, color: AppColors.primary),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.tr('question_nudge_discover_locked'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  child: LinearProgressIndicator(
                                    value: ((user?.questionCount ?? 0) / 2).clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  context.tr('question_nudge_progress')
                                      .replaceAll('{count}', '${user?.questionCount ?? 0}'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                            icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onPrimary, size: 18),
                            label: Text(context.tr('question_nudge_add_button')),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
```

**Step 3: Commit**

```bash
git add lib/features/discover/screens/discover_screen.dart
git commit -m "feat: add blurred lock overlay to discover when user has < 2 questions"
```

---

### Task 9: Flutter — Bottom navigation badge dot ekle

**Files:**
- Modify: `lib/routing/app_routes.dart`

**Step 1: _MainShell'i ConsumerWidget'a çevir ve badge ekle**

`_MainShell` class'ını `ConsumerWidget`'a çevir (ProviderScope zaten app root'ta var):

```dart
class _MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _MainShell({required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).valueOrNull;
    final showProfileBadge = (user?.questionCount ?? 0) < AppConstants.minQuestions;

    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            color: const Color(0xFFBB86FC).withValues(alpha: 0.3),
          ),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: QIcon(QIcons.icCompass, size: 24),
                selectedIcon: QIcon(QIcons.icCompassFilled, size: 24),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: QIcon(QIcons.icHeart, size: 24),
                selectedIcon: QIcon(QIcons.icHeartFilled, size: 24),
                label: 'Matches',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: showProfileBadge,
                  smallSize: 10,
                  backgroundColor: AppColors.error,
                  child: QIcon(QIcons.icUser, size: 24),
                ),
                selectedIcon: Badge(
                  isLabelVisible: showProfileBadge,
                  smallSize: 10,
                  backgroundColor: AppColors.error,
                  child: QIcon(QIcons.icUserFilled, size: 24),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Gerekli import'ları ekle**

`app_router.dart` dosyasına (part directive olan ana dosya) ekle:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
```

Not: `app_routes.dart` bir `part` dosyası olduğu için import'lar `app_router.dart`'ta olmalı. Mevcut import'ları kontrol et, çakışanları ekleme.

**Step 3: Commit**

```bash
git add lib/routing/app_router.dart lib/routing/app_routes.dart
git commit -m "feat: add badge dot to profile tab when questions < 2"
```

---

### Task 10: Flutter — Soru ekleme kutlama animasyonu

**Files:**
- Modify: `lib/features/profile/screens/questions_screen.dart`
- Modify: `lib/providers/question_provider.dart`

**Step 1: QuestionNotifier'da kutlama state'i ekle**

`question_provider.dart`'ta `createQuestion` metodunu güncelle — 2. soru oluşturulduğunda user provider'ı da refresh et:

```dart
import 'package:qulo_v2/core/constants/app_constants.dart';

  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data) async {
    final result = await ref.read(questionRepositoryProvider).createQuestion(data);
    result.when(
      success: (_) {
        fetchQuestions();
        // Refresh user provider to update questionCount across the app
        ref.read(userProvider.notifier).fetchMe();
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteQuestion(int orderNum) async {
    final result = await ref.read(questionRepositoryProvider).deleteQuestion(orderNum);
    result.when(
      success: (_) {
        fetchQuestions();
        // Refresh user provider to update questionCount across the app
        ref.read(userProvider.notifier).fetchMe();
      },
      failure: (_) {},
    );
    return result;
  }
```

Import ekle:

```dart
import 'package:qulo_v2/providers/user_provider.dart';
```

**Step 2: QuestionsScreen'e kutlama dialog'u ekle**

`questions_screen.dart`'ta `_showAddDialog` içindeki `onPressed` callback'inde, soru oluşturulduktan sonra kutlama kontrolü ekle:

Mevcut `onPressed` callback'i şu şekilde güncelle:

```dart
                onPressed: () async {
                  final questions = ref.read(questionProvider).valueOrNull ?? [];
                  final wasBelow = questions.length < AppConstants.minQuestions;
                  final result = await ref.read(questionProvider.notifier).createQuestion({
                    'order_num': questions.length + 1,
                    'question_text': textCtrl.text,
                    'correct_answer': correctAnswer,
                    'answer_1': a1.text,
                    'answer_2': a2.text,
                    'answer_3': a3.text,
                    'answer_4': a4.text,
                  });
                  nav.closeOverlay();

                  // Show celebration if user just reached minimum questions
                  if (wasBelow && questions.length + 1 >= AppConstants.minQuestions) {
                    result.when(
                      success: (_) => _showCelebrationDialog(),
                      failure: (_) {},
                    );
                  }
                },
```

**Step 3: Kutlama dialog metodunu ekle**

`_QuestionsScreenState` class'ına yeni metod:

```dart
  void _showCelebrationDialog() {
    final nav = ref.read(navigationServiceProvider);
    nav.showAppDialog(
      CustomDialog(
        name: 'question_celebration',
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Icon(Icons.celebration, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('question_nudge_celebration_title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    nav.closeOverlay();
                    ref.read(navigationServiceProvider).go(RouteNames.discover);
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(context.tr('question_nudge_celebration_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

**Step 4: Gerekli import'ları ekle**

```dart
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/providers/user_provider.dart';
```

**Step 5: Commit**

```bash
git add lib/providers/question_provider.dart lib/features/profile/screens/questions_screen.dart
git commit -m "feat: add celebration dialog when user reaches minimum questions"
```

---

### Task 11: Doğrulama

**Step 1: Flutter analyze çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

Hata varsa düzelt.

**Step 2: Tüm değişikliklerin çalıştığını doğrula**

```bash
flutter run
```

Test senaryoları:
1. Sorusu 0 olan kullanıcı → Discover'da blur overlay görmeli
2. Sorusu 0 olan kullanıcı → Profil'de banner görmeli
3. Sorusu 0 olan kullanıcı → Edit profil'de info banner görmeli
4. Sorusu 0 olan kullanıcı → Bottom nav'da badge görmeli
5. 2. soruyu eklediğinde → Kutlama dialog'u görmeli
6. Sorusu 2+ olan kullanıcı → Hiçbir nudge görmemeli
7. Discover'da sorusu 2'den az olan diğer kullanıcılar görünmemeli

**Step 3: Final commit**

```bash
git add -A
git commit -m "feat: question gate & nudge system — complete implementation"
```
