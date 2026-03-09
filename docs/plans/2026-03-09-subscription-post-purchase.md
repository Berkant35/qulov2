# Subscription Post-Purchase Flow & Daily Stats Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Satın alma sonrası kutlama dialog'u + diamonds'a yönlendirme, profile'da abonelik bilgisi, diamonds'ta aylık haklar kartı ve backend'de günlük counter sistemi.

**Architecture:** Backend'e daily-stats endpoint + discover/swipe'da lazy reset & limit enforcement. Flutter'da celebration dialog, monthly benefits card, profile badge/menü satırı. Provider invalidation ile otomatik refresh.

**Tech Stack:** Flutter/Riverpod, Node.js/Express, Supabase PostgreSQL, Zod validation

---

### Task 1: Backend — Daily Stats Endpoint & Lazy Reset

**Files:**
- Modify: `server/src/services/subscription.service.ts`
- Modify: `server/src/controllers/subscription.controller.ts`
- Modify: `server/src/routes/subscription.routes.ts`
- Modify: `server/src/utils/errors.ts`

**Step 1: Add DAILY_LIMIT_EXCEEDED error**

In `server/src/utils/errors.ts`, add after `DUPLICATE_TRANSACTION`:

```typescript
  DAILY_LIMIT_EXCEEDED: (resource: string) =>
    new AppError("DAILY_LIMIT_EXCEEDED", 403, `Daily ${resource} limit exceeded`, { resource }),
```

**Step 2: Add getDailyStats and resetIfNeeded to subscription.service.ts**

Add to `SubscriptionService` class:

```typescript
  async getDailyStats(userId: string) {
    const { data: user, error } = await supabase
      .from('users')
      .select('daily_swipes_used, daily_swipes_reset_at, daily_undos_used, subscription_plan, subscription_expires_at')
      .eq('id', userId)
      .single();

    if (error || !user) throw Errors.USER_NOT_FOUND();

    // Lazy reset: if reset_at is before today UTC midnight
    const now = new Date();
    const resetAt = user.daily_swipes_reset_at ? new Date(user.daily_swipes_reset_at) : new Date(0);
    const todayMidnight = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    let dailySwipesUsed = user.daily_swipes_used ?? 0;
    let dailyUndosUsed = user.daily_undos_used ?? 0;

    if (resetAt < todayMidnight) {
      // Reset counters
      await supabase
        .from('users')
        .update({
          daily_swipes_used: 0,
          daily_undos_used: 0,
          daily_swipes_reset_at: now.toISOString(),
        })
        .eq('id', userId);

      dailySwipesUsed = 0;
      dailyUndosUsed = 0;
    }

    const plan = user.subscription_plan as SubscriptionPlan | null;
    const isActive = user.subscription_expires_at
      ? new Date(user.subscription_expires_at) > now
      : false;
    const effectivePlan = isActive ? (plan || 'free') : 'free';
    const limits = SUBSCRIPTION_LIMITS[effectivePlan];

    // Get question count
    const { count: questionsCreated } = await supabase
      .from('questions')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId);

    return {
      dailyDiscoversUsed: dailySwipesUsed,
      dailyDiscoversLimit: limits.dailyDiscovers === Infinity ? -1 : limits.dailyDiscovers,
      dailyUndosUsed: dailyUndosUsed,
      dailyUndosLimit: limits.dailyUndos === Infinity ? -1 : limits.dailyUndos,
      questionsCreated: questionsCreated ?? 0,
      questionsLimit: limits.maxQuestions,
      monthlyPurpleBonus: limits.monthlyPurpleBonus,
      passportMode: limits.passportMode,
      hasAds: limits.hasAds,
    };
  }

  async incrementDailySwipes(userId: string): Promise<void> {
    const stats = await this.getDailyStats(userId);
    if (stats.dailyDiscoversLimit !== -1 && stats.dailyDiscoversUsed >= stats.dailyDiscoversLimit) {
      throw Errors.DAILY_LIMIT_EXCEEDED('discover');
    }
    await supabase.rpc('increment_field', {
      table_name: 'users',
      field_name: 'daily_swipes_used',
      row_id: userId,
    });
  }

  async incrementDailyUndos(userId: string): Promise<void> {
    const stats = await this.getDailyStats(userId);
    if (stats.dailyUndosLimit !== -1 && stats.dailyUndosUsed >= stats.dailyUndosLimit) {
      throw Errors.DAILY_LIMIT_EXCEEDED('undo');
    }
    await supabase
      .from('users')
      .update({ daily_undos_used: (stats.dailyUndosUsed + 1) })
      .eq('id', userId);
  }
```

**Step 3: Add dailyStatsHandler to subscription.controller.ts**

```typescript
export const dailyStatsHandler = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const stats = await subscriptionService.getDailyStats(req.user!.userId);
    res.json(stats);
  } catch (error) {
    next(error);
  }
};
```

**Step 4: Add route in subscription.routes.ts**

```typescript
import {
  getSubscriptionStatusHandler,
  activateSubscriptionHandler,
  dailyStatsHandler,
} from '../controllers/subscription.controller.js';

// Add after existing routes:
router.get('/daily-stats', dailyStatsHandler);
```

**Step 5: Add increment_field RPC (or use raw update)**

Since `increment_field` RPC may not exist, use direct SQL increment instead. Replace the `incrementDailySwipes` RPC call with:

```typescript
  async incrementDailySwipes(userId: string): Promise<void> {
    const stats = await this.getDailyStats(userId);
    if (stats.dailyDiscoversLimit !== -1 && stats.dailyDiscoversUsed >= stats.dailyDiscoversLimit) {
      throw Errors.DAILY_LIMIT_EXCEEDED('discover');
    }
    await supabase
      .from('users')
      .update({ daily_swipes_used: stats.dailyDiscoversUsed + 1 })
      .eq('id', userId);
  }
```

**Step 6: Commit**

```bash
git add server/src/services/subscription.service.ts server/src/controllers/subscription.controller.ts server/src/routes/subscription.routes.ts server/src/utils/errors.ts
git commit -m "feat: add daily-stats endpoint with lazy reset"
```

---

### Task 2: Backend — Discover Limit Enforcement

**Files:**
- Modify: `server/src/services/matching.service.ts`

**Step 1: Add limit check to swipe method**

At the top of `matching.service.ts`, add import:

```typescript
import { subscriptionService } from './subscription.service.js';
```

In the `swipe()` method (line 258), after the self-swipe check and before the insert, add:

```typescript
    // Daily swipe limit check + increment
    await subscriptionService.incrementDailySwipes(swiperId);
```

This will:
- Lazy-reset if new day
- Check if limit exceeded → throw DAILY_LIMIT_EXCEEDED
- Increment counter

**Step 2: Commit**

```bash
git add server/src/services/matching.service.ts
git commit -m "feat: enforce daily discover limit on swipe"
```

---

### Task 3: Flutter — DailyStats Model & Provider

**Files:**
- Create: `lib/data/models/daily_stats_model.dart`
- Modify: `lib/core/network/services/subscription_service.dart`
- Modify: `lib/core/network/services/subscription_service.g.dart`
- Modify: `lib/data/repositories/subscription_repository.dart`
- Create: `lib/providers/daily_stats_provider.dart`
- Modify: `lib/providers/api_provider.dart`

**Step 1: Create DailyStats model**

```dart
// lib/data/models/daily_stats_model.dart
import 'package:equatable/equatable.dart';

class DailyStats extends Equatable {
  final int dailyDiscoversUsed;
  final int dailyDiscoversLimit;
  final int dailyUndosUsed;
  final int dailyUndosLimit;
  final int questionsCreated;
  final int questionsLimit;
  final int monthlyPurpleBonus;
  final bool passportMode;
  final bool hasAds;

  const DailyStats({
    required this.dailyDiscoversUsed,
    required this.dailyDiscoversLimit,
    required this.dailyUndosUsed,
    required this.dailyUndosLimit,
    required this.questionsCreated,
    required this.questionsLimit,
    required this.monthlyPurpleBonus,
    required this.passportMode,
    required this.hasAds,
  });

  /// -1 means unlimited
  bool get isDiscoverUnlimited => dailyDiscoversLimit == -1;
  bool get isUndoUnlimited => dailyUndosLimit == -1;

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      dailyDiscoversUsed: json['dailyDiscoversUsed'] as int? ?? 0,
      dailyDiscoversLimit: json['dailyDiscoversLimit'] as int? ?? 50,
      dailyUndosUsed: json['dailyUndosUsed'] as int? ?? 0,
      dailyUndosLimit: json['dailyUndosLimit'] as int? ?? 0,
      questionsCreated: json['questionsCreated'] as int? ?? 0,
      questionsLimit: json['questionsLimit'] as int? ?? 4,
      monthlyPurpleBonus: json['monthlyPurpleBonus'] as int? ?? 0,
      passportMode: json['passportMode'] as bool? ?? false,
      hasAds: json['hasAds'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        dailyDiscoversUsed, dailyDiscoversLimit,
        dailyUndosUsed, dailyUndosLimit,
        questionsCreated, questionsLimit,
        monthlyPurpleBonus, passportMode, hasAds,
      ];
}
```

**Step 2: Add getDailyStats to subscription_service.dart**

```dart
@GET('/subscriptions/daily-stats')
Future<DailyStats> getDailyStats();
```

And add corresponding generated code in `subscription_service.g.dart`.

**Step 3: Add to subscription_repository.dart**

```dart
Future<Result<DailyStats>> getDailyStats() async {
  try {
    final data = await _service.getDailyStats();
    return Result.success(data);
  } catch (e) {
    return Result.failure(AppException.fromError(e));
  }
}
```

**Step 4: Create daily_stats_provider.dart**

```dart
// lib/providers/daily_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

final dailyStatsProvider = AsyncNotifierProvider<DailyStatsNotifier, DailyStats>(
  DailyStatsNotifier.new,
);

class DailyStatsNotifier extends AsyncNotifier<DailyStats> {
  @override
  Future<DailyStats> build() => fetchStats();

  Future<DailyStats> fetchStats() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.getDailyStats();
    return result.when(
      success: (data) => data,
      failure: (_) => const DailyStats(
        dailyDiscoversUsed: 0,
        dailyDiscoversLimit: 50,
        dailyUndosUsed: 0,
        dailyUndosLimit: 0,
        questionsCreated: 0,
        questionsLimit: 4,
        monthlyPurpleBonus: 0,
        passportMode: false,
        hasAds: true,
      ),
    );
  }
}
```

**Step 5: Commit**

```bash
git add lib/data/models/daily_stats_model.dart lib/providers/daily_stats_provider.dart lib/core/network/services/subscription_service.dart lib/core/network/services/subscription_service.g.dart lib/data/repositories/subscription_repository.dart
git commit -m "feat: add DailyStats model, provider and API layer"
```

---

### Task 4: Flutter — Celebration Dialog

**Files:**
- Create: `lib/features/diamonds/widgets/celebration_dialog.dart`
- Modify: `lib/features/diamonds/screens/subscription_comparison_screen.dart`
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Add i18n keys**

In `app_localizations.dart`, add to both EN and TR maps:

```
// EN
'celebration_title': 'Welcome to {plan}!',
'celebration_diamonds': '+{amount} Purple Diamonds',
'celebration_diamonds_desc': 'Your monthly bonus has been added',
'celebration_button': 'Awesome!',
'sub_my_subscription': 'My Subscription',
'sub_free_upgrade': 'Free Plan • Upgrade',
'monthly_benefits_title': 'My Benefits',
'benefit_daily_discovers': 'Daily Discovers',
'benefit_daily_undos': 'Daily Undos',
'benefit_question_slots': 'Question Slots',
'benefit_monthly_diamonds': 'Monthly Diamonds',
'benefit_passport': 'Passport Mode',
'benefit_ads': 'Ads',
'benefit_unlimited': 'Unlimited',
'benefit_given': 'Given',
'benefit_active': 'Active',
'benefit_inactive': 'Inactive',
'benefit_none': 'None',
'benefit_no_ads': 'No Ads',
'benefit_has_ads': 'Has Ads',

// TR
'celebration_title': '{plan} planına hoş geldin!',
'celebration_diamonds': '+{amount} Mor Elmas',
'celebration_diamonds_desc': 'Aylık bonusun hesabına eklendi',
'celebration_button': 'Harika!',
'sub_my_subscription': 'Aboneliğim',
'sub_free_upgrade': 'Ücretsiz Plan • Yükselt',
'monthly_benefits_title': 'Haklarım',
'benefit_daily_discovers': 'Günlük Keşif',
'benefit_daily_undos': 'Günlük Geri Alma',
'benefit_question_slots': 'Soru Slotu',
'benefit_monthly_diamonds': 'Aylık Elmas',
'benefit_passport': 'Pasaport Modu',
'benefit_ads': 'Reklamlar',
'benefit_unlimited': 'Sınırsız',
'benefit_given': 'Verildi',
'benefit_active': 'Aktif',
'benefit_inactive': 'Kapalı',
'benefit_none': 'Yok',
'benefit_no_ads': 'Reklam Yok',
'benefit_has_ads': 'Reklam Var',
```

**Step 2: Create celebration_dialog.dart**

```dart
// lib/features/diamonds/widgets/celebration_dialog.dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class CelebrationDialog extends StatelessWidget {
  final String planName;
  final int diamondBonus;

  const CelebrationDialog({
    super.key,
    required this.planName,
    required this.diamondBonus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.primary.withAlpha(77)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient plan badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                planName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              context.tr('celebration_title', args: {'plan': planName}),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Diamond bonus
            if (diamondBonus > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DiamondIcon.purple(size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    context.tr('celebration_diamonds', args: {'amount': '$diamondBonus'}),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('celebration_diamonds_desc'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Button
            AppButton(
              label: context.tr('celebration_button'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Update subscription_comparison_screen.dart purchase handler**

Replace `_handlePurchase` method:

```dart
  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    String plan,
  ) async {
    final productId = plan == 'premium' ? 'qulopremiummonthly' : 'quloplusmonthly2';
    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchaseByProductId(productId);

    if (!context.mounted) return;

    if (success) {
      // Show celebration dialog
      final planName = plan == 'premium'
          ? context.tr('sub_plan_premium')
          : context.tr('sub_plan_plus');
      final bonus = plan == 'premium' ? 1500 : 500;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CelebrationDialog(
          planName: planName,
          diamondBonus: bonus,
        ),
      );

      if (!context.mounted) return;

      // Invalidate providers so diamonds screen shows fresh data
      ref.invalidate(diamondProvider);
      ref.invalidate(subscriptionProvider);
      ref.invalidate(dailyStatsProvider);

      // Navigate to diamonds screen (pop comparison, go to diamonds)
      final nav = ref.read(navigationServiceProvider);
      nav.pop();
      nav.go(RouteNames.diamonds);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('purchase_failed'))),
      );
    }
  }
```

Add required imports at top of file:
```dart
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
```

**Step 4: Commit**

```bash
git add lib/features/diamonds/widgets/celebration_dialog.dart lib/features/diamonds/screens/subscription_comparison_screen.dart lib/core/l10n/app_localizations.dart
git commit -m "feat: add celebration dialog after subscription purchase"
```

---

### Task 5: Flutter — Profile Subscription Badge & Menu

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Add subscription provider import**

```dart
import 'package:qulo_v2/providers/subscription_provider.dart';
```

**Step 2: Add subscription badge under name (after line 127)**

After the name/age Text widget and before city row, add:

```dart
                // ─── Subscription Badge ───
                Builder(builder: (context) {
                  final subAsync = ref.watch(subscriptionProvider);
                  final sub = subAsync.valueOrNull;
                  if (sub == null || sub.isFree) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        sub.isPremium ? 'Premium' : 'Plus',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
```

**Step 3: Add subscription menu item (after Diamonds menu item, before Passport)**

```dart
                _MenuItem(
                  iconPath: QIcons.icStar,
                  title: context.tr('sub_my_subscription'),
                  subtitle: (() {
                    final sub = ref.watch(subscriptionProvider).valueOrNull;
                    if (sub == null || sub.isFree) return context.tr('sub_free_upgrade');
                    final planLabel = sub.isPremium ? 'Premium' : 'Plus';
                    if (sub.expiresAt != null) {
                      final date = DateTime.tryParse(sub.expiresAt!);
                      if (date != null) {
                        final formatted = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                        return '$planLabel • $formatted';
                      }
                    }
                    return planLabel;
                  })(),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.subscriptions),
                ),
```

Note: Check if `RouteNames.subscriptions` exists. If not, check the actual route name for subscription comparison screen and use that. Also check if `QIcons.icStar` exists — if not, use `QIcons.icAward` or another appropriate icon.

**Step 4: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: add subscription badge and menu item to profile"
```

---

### Task 6: Flutter — Monthly Benefits Card

**Files:**
- Create: `lib/features/diamonds/widgets/monthly_benefits_card.dart`
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`

**Step 1: Create monthly_benefits_card.dart**

```dart
// lib/features/diamonds/widgets/monthly_benefits_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';

class MonthlyBenefitsCard extends StatelessWidget {
  final DailyStats stats;
  final bool isFree;
  final VoidCallback? onUpgrade;

  const MonthlyBenefitsCard({
    super.key,
    required this.stats,
    required this.isFree,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isFree
              ? theme.colorScheme.outline.withValues(alpha: 0.3)
              : AppColors.primary.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('monthly_benefits_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Daily Discovers
          _BenefitRow(
            icon: QIcons.icCompass,
            label: context.tr('benefit_daily_discovers'),
            value: stats.isDiscoverUnlimited
                ? context.tr('benefit_unlimited')
                : '${stats.dailyDiscoversUsed}/${stats.dailyDiscoversLimit}',
            progress: stats.isDiscoverUnlimited
                ? null
                : stats.dailyDiscoversLimit > 0
                    ? stats.dailyDiscoversUsed / stats.dailyDiscoversLimit
                    : 0,
            color: AppColors.primary,
          ),

          // Question Slots
          _BenefitRow(
            icon: QIcons.icHelpCircle,
            label: context.tr('benefit_question_slots'),
            value: '${stats.questionsCreated}/${stats.questionsLimit}',
            progress: stats.questionsLimit > 0
                ? stats.questionsCreated / stats.questionsLimit
                : 0,
            color: AppColors.secondary,
          ),

          // Daily Undos
          _BenefitRow(
            icon: QIcons.icSkipForward,
            label: context.tr('benefit_daily_undos'),
            value: stats.dailyUndosLimit == 0
                ? context.tr('benefit_none')
                : stats.isUndoUnlimited
                    ? context.tr('benefit_unlimited')
                    : '${stats.dailyUndosUsed}/${stats.dailyUndosLimit}',
            progress: stats.dailyUndosLimit == 0
                ? null
                : stats.isUndoUnlimited
                    ? null
                    : stats.dailyUndosLimit > 0
                        ? stats.dailyUndosUsed / stats.dailyUndosLimit
                        : 0,
            color: AppColors.primary,
          ),

          // Monthly Diamonds
          _BenefitRow(
            iconWidget: const DiamondIcon.purple(size: 16),
            label: context.tr('benefit_monthly_diamonds'),
            value: stats.monthlyPurpleBonus > 0
                ? '${stats.monthlyPurpleBonus} ✓'
                : context.tr('benefit_none'),
            color: AppColors.primary,
          ),

          // Passport Mode
          _BenefitRow(
            icon: QIcons.icGlobe,
            label: context.tr('benefit_passport'),
            value: stats.passportMode
                ? context.tr('benefit_active')
                : context.tr('benefit_inactive'),
            color: stats.passportMode ? AppColors.secondary : theme.colorScheme.onSurfaceVariant,
          ),

          // Ads
          _BenefitRow(
            icon: QIcons.icEyeOff,
            label: context.tr('benefit_ads'),
            value: stats.hasAds
                ? context.tr('benefit_has_ads')
                : context.tr('benefit_no_ads'),
            color: stats.hasAds ? theme.colorScheme.onSurfaceVariant : AppColors.secondary,
            showDivider: false,
          ),

          // Upgrade CTA for free users
          if (isFree && onUpgrade != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onUpgrade,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  context.tr('get_started'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final double? progress;
  final Color color;
  final bool showDivider;

  const _BenefitRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
    this.progress,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (iconWidget != null)
                SizedBox(width: 16, height: 16, child: iconWidget!)
              else
                QIcon(icon!, size: 16, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                          color: color,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ],
    );
  }
}
```

**Step 2: Add MonthlyBenefitsCard to diamonds_screen.dart**

Add import:
```dart
import 'package:qulo_v2/features/diamonds/widgets/monthly_benefits_card.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
```

In the build method, after the SubscriptionBanner widget, add the benefits card:

```dart
            // ─── Monthly Benefits Card ───
            Builder(builder: (context) {
              final statsAsync = ref.watch(dailyStatsProvider);
              final subAsync = ref.watch(subscriptionProvider);
              return statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) {
                  final isFree = subAsync.valueOrNull?.isFree ?? true;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: MonthlyBenefitsCard(
                      stats: stats,
                      isFree: isFree,
                      onUpgrade: isFree
                          ? () => ref.read(navigationServiceProvider).go(RouteNames.subscriptions)
                          : null,
                    ),
                  );
                },
              );
            }),
```

Also add `dailyStatsProvider` fetch in `initState`:

```dart
ref.read(dailyStatsProvider.notifier).fetchStats();
```

**Step 3: Commit**

```bash
git add lib/features/diamonds/widgets/monthly_benefits_card.dart lib/features/diamonds/screens/diamonds_screen.dart
git commit -m "feat: add monthly benefits card with daily stats to diamonds screen"
```

---

### Task 7: i18n & Final Integration

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Verify all i18n keys added in Task 4 are present**

Ensure both EN and TR maps contain all the keys listed in Task 4 Step 1.

**Step 2: Verify `context.tr()` supports named args**

Check how `context.tr()` handles `args` parameter. If it uses positional `{0}` style instead of named `{plan}`, adjust celebration dialog calls accordingly.

**Step 3: Run flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

Fix any issues.

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete subscription post-purchase flow with daily stats"
```

---

## Summary

| Task | Description | Files |
|------|------------|-------|
| 1 | Backend daily-stats endpoint + lazy reset | 4 server files |
| 2 | Discover limit enforcement in swipe | 1 server file |
| 3 | Flutter DailyStats model + provider | 5 Flutter files |
| 4 | Celebration dialog + purchase flow | 3 Flutter files |
| 5 | Profile badge + subscription menu | 1 Flutter file |
| 6 | Monthly benefits card + diamonds integration | 2 Flutter files |
| 7 | i18n verification + analyze | 1 Flutter file |
