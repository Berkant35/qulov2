# Performance Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kullanicinin soru performansi, elmas ekonomisi ve genel istatistiklerini gosteren yeni dashboard ekrani + sorular ekranindaki bos analytics ikonu bug fix'i.

**Architecture:** Mevcut `questionAnalyticsProvider` ve `diamondProvider` reuse edilir. Yeni `PerformanceDashboardScreen` 3 bolumden olusur: ozet grid, elmas ekonomisi, soru performansi. Her bolum ayri widget dosyasi.

**Tech Stack:** Flutter, Riverpod, GoRouter, i18n (translations/*.dart), AnalyticsManager

**Spec:** `docs/superpowers/specs/2026-03-22-performance-dashboard-design.md`

---

## File Structure

### New Files
- `lib/features/performance/screens/performance_dashboard_screen.dart` — ana ekran
- `lib/features/performance/mixins/performance_dashboard_mixin.dart` — ekran logic'i
- `lib/features/performance/widgets/performance_summary_grid.dart` — 2x2 ozet kartlari
- `lib/features/performance/widgets/diamond_economy_section.dart` — elmas ekonomisi
- `lib/features/performance/widgets/question_performance_section.dart` — soru performansi
- `lib/features/performance/widgets/diamond_transaction_tile.dart` — islem satiri

### Modified Files
- `lib/routing/route_names.dart` — `performance` route name
- `lib/routing/app_router.dart` — import
- `lib/routing/app_routes.dart` — route tanimı
- `lib/core/services/analytics_events.dart` — 3 yeni event
- `lib/core/l10n/translations/*.dart` — i18n key'leri (16 dosya)
- `lib/features/profile/widgets/profile_menu_list.dart` — menu satiri
- `lib/features/profile/screens/profile_screen.dart` — callback
- `lib/features/profile/screens/questions_screen.dart:44` — bug fix
- `lib/features/profile/mixins/questions_screen_mixin.dart` — analytics navigasyonu

---

## Task 1: Bug Fix — Sorular Ekrani Analytics Ikonu

**Files:**
- Modify: `lib/features/profile/screens/questions_screen.dart:43-46`
- Modify: `lib/features/profile/mixins/questions_screen_mixin.dart`

- [ ] **Step 1:** `questions_screen_mixin.dart`'a analytics navigasyonu ekle

Mixin'e yeni metod ekle:

```dart
  void openAnalytics() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.questionAnalyticsView);
    ref.read(navigationServiceProvider).push(RouteNames.questionAnalytics);
  }
```

- [ ] **Step 2:** `questions_screen.dart`'ta bos callback'i duzelt

Satir 43-46'yi degistir:

```dart
        IconButton(
          onPressed: openAnalytics,
          icon: QIcon(QIcons.icChart, size: 22, color: context.appColors.textSecondary),
        ),
```

- [ ] **Step 3:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/features/profile/screens/questions_screen.dart lib/features/profile/mixins/questions_screen_mixin.dart
```

- [ ] **Step 4:** Commit

```bash
git add lib/features/profile/screens/questions_screen.dart lib/features/profile/mixins/questions_screen_mixin.dart
git commit -m "fix(questions): wire analytics icon to QuestionAnalyticsScreen"
```

---

## Task 2: Route + Analytics Events + i18n

**Files:**
- Modify: `lib/routing/route_names.dart`
- Modify: `lib/routing/app_routes.dart`
- Modify: `lib/routing/app_router.dart`
- Modify: `lib/core/services/analytics_events.dart`
- Modify: `lib/core/l10n/translations/*.dart` (16 dosya)

- [ ] **Step 1:** `RouteNames`'e `performance` ekle

```dart
  static const performance = 'performance';
```

- [ ] **Step 2:** `app_routes.dart`'ta profile alt route'larina ekle (subscription yanina)

```dart
            GoRoute(
              path: 'performance',
              name: RouteNames.performance,
              builder: (context, state) => const PerformanceDashboardScreen(),
            ),
```

- [ ] **Step 3:** `app_router.dart`'a import ekle

```dart
import 'package:qulo_v2/features/performance/screens/performance_dashboard_screen.dart';
```

- [ ] **Step 4:** Analytics events ekle

`analytics_events.dart`'a:

```dart
  // ─── Performance Dashboard ─────────────────────────────────────────
  static const String performanceDashboardOpened = 'performance_dashboard_opened';
  static const String performanceViewAllDiamonds = 'performance_view_all_diamonds';
  static const String performanceBestQuestionTapped = 'performance_best_question_tapped';
```

- [ ] **Step 5:** i18n key'leri tum dil dosyalarina ekle

`tr.dart`'a:
```dart
  'performance_dashboard': 'Performans Analizi',
  'performance_analysis': 'Performans Analizi',
  'total_solves': 'Toplam Cozulme',
  'success_rate': 'Basari Orani',
  'green_earned': 'Kazanilan Yesil',
  'purple_spent': 'Harcanan Mor',
  'diamond_economy': 'Elmas Ekonomisi',
  'recent_transactions': 'Son Islemler',
  'view_all': 'Tumunu Gor',
  'question_performance': 'Soru Performansi',
  'best_question': 'En Iyi Sorum',
  'hardest_question': 'En Zor Sorum',
  'avg_solve_time': 'Ort. Cozum Suresi',
  'difficulty_distribution': 'Zorluk Dagilimi',
  'no_data_yet': 'Henuz veri yok',
  'no_transactions': 'Henuz islem yok',
  'no_solves_yet': 'Henuz cozum yok',
  'difficulty_easy': 'Kolay',
  'difficulty_medium': 'Orta',
  'difficulty_hard': 'Zor',
  'difficulty_legendary': 'Efsane',
  'difficulty_unranked': 'Siralanmamis',
```

`en.dart`'a:
```dart
  'performance_dashboard': 'Performance Analysis',
  'performance_analysis': 'Performance Analysis',
  'total_solves': 'Total Solves',
  'success_rate': 'Success Rate',
  'green_earned': 'Green Earned',
  'purple_spent': 'Purple Spent',
  'diamond_economy': 'Diamond Economy',
  'recent_transactions': 'Recent Transactions',
  'view_all': 'View All',
  'question_performance': 'Question Performance',
  'best_question': 'Best Question',
  'hardest_question': 'Hardest Question',
  'avg_solve_time': 'Avg. Solve Time',
  'difficulty_distribution': 'Difficulty Distribution',
  'no_data_yet': 'No data yet',
  'no_transactions': 'No transactions yet',
  'no_solves_yet': 'No solves yet',
  'difficulty_easy': 'Easy',
  'difficulty_medium': 'Medium',
  'difficulty_hard': 'Hard',
  'difficulty_legendary': 'Legendary',
  'difficulty_unranked': 'Unranked',
```

Diger 14 dil dosyasina Ingilizce degerlerle ekle.

- [ ] **Step 6:** Commit

```bash
git add lib/routing/ lib/core/services/analytics_events.dart lib/core/l10n/translations/
git commit -m "feat(performance): add route, analytics events, and i18n keys"
```

---

## Task 3: Performance Summary Grid Widget

**Files:**
- Create: `lib/features/performance/widgets/performance_summary_grid.dart`

- [ ] **Step 1:** Ozet grid widget'ini olustur

2x2 grid, 4 istatistik karti. Her kart: ikon + deger + etiket.

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';

class PerformanceSummaryGrid extends StatelessWidget {
  final QuestionAnalyticsTotals totals;

  const PerformanceSummaryGrid({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          icon: Icons.check_circle_outline,
          iconColor: context.appColors.secondary,
          value: '${totals.totalSolveCount}',
          label: context.tr('total_solves'),
        ),
        _StatCard(
          icon: Icons.trending_up,
          iconColor: context.appColors.primary,
          value: '%${totals.overallSuccessRate}',
          label: context.tr('success_rate'),
        ),
        _StatCard(
          iconWidget: const DiamondIcon.green(size: 20),
          value: '${totals.totalGreenEarned}',
          label: context.tr('green_earned'),
        ),
        _StatCard(
          iconWidget: const DiamondIcon.purple(size: 20),
          value: '-',
          label: context.tr('purple_spent'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final String value;
  final String label;

  const _StatCard({
    this.icon,
    this.iconColor,
    this.iconWidget,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          iconWidget ?? Icon(icon, size: 24, color: iconColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2:** `dart analyze` calistir
- [ ] **Step 3:** Commit

```bash
git add lib/features/performance/widgets/performance_summary_grid.dart
git commit -m "feat(performance): create PerformanceSummaryGrid widget"
```

---

## Task 4: Diamond Transaction Tile + Diamond Economy Section

**Files:**
- Create: `lib/features/performance/widgets/diamond_transaction_tile.dart`
- Create: `lib/features/performance/widgets/diamond_economy_section.dart`

- [ ] **Step 1:** Transaction tile widget'ini olustur

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';

class DiamondTransactionTile extends StatelessWidget {
  final DiamondTransaction transaction;

  const DiamondTransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGreen = transaction.type == 'GREEN';
    final isPositive = transaction.amount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          isGreen ? const DiamondIcon.green(size: 20) : const DiamondIcon.purple(size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reasonLabel(context, transaction.reason),
                  style: theme.textTheme.bodyMedium,
                ),
                if (transaction.createdAt != null)
                  Text(
                    _formatDate(transaction.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.amount}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive ? context.appColors.secondary : context.appColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(BuildContext context, String reason) {
    return switch (reason) {
      'POWER_USED' => context.tr('reason_power_used'),
      'POWER_REWARD' => context.tr('reason_power_reward'),
      'IAP' => context.tr('reason_iap'),
      'REFERRAL' => context.tr('reason_referral'),
      'SUBSCRIPTION_BONUS' => context.tr('reason_subscription'),
      'BOOST' => context.tr('reason_boost'),
      _ => reason.replaceAll('_', ' ').toLowerCase(),
    };
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
```

**Not:** `reason_power_used`, `reason_power_reward` vb. i18n key'leri zaten mevcut olabilir. Yoksa eklenmeli — kontrol et.

- [ ] **Step 2:** Economy section widget'ini olustur

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/features/performance/widgets/diamond_transaction_tile.dart';

class DiamondEconomySection extends StatelessWidget {
  final int greenBalance;
  final int purpleBalance;
  final List<DiamondTransaction> recentTransactions;
  final VoidCallback onViewAll;

  const DiamondEconomySection({
    super.key,
    required this.greenBalance,
    required this.purpleBalance,
    required this.recentTransactions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('diamond_economy'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Balance row
        Row(
          children: [
            Expanded(child: _BalanceChip(icon: const DiamondIcon.green(size: 18), value: greenBalance)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _BalanceChip(icon: const DiamondIcon.purple(size: 18), value: purpleBalance)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Recent transactions
        Text(
          context.tr('recent_transactions'),
          style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                context.tr('no_transactions'),
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
              ),
            ),
          )
        else ...[
          ...recentTransactions.take(10).map(
            (t) => DiamondTransactionTile(transaction: t),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AppButton(
              label: context.tr('view_all'),
              onPressed: onViewAll,
              variant: AppButtonVariant.text,
            ),
          ),
        ],
      ],
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final Widget icon;
  final int value;
  const _BalanceChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

**Not:** `AppButton` `variant` parametresi kontrol et. Yoksa `onPressed` icin basit `TextButton` kullan.

- [ ] **Step 3:** `dart analyze` calistir
- [ ] **Step 4:** Commit

```bash
git add lib/features/performance/widgets/
git commit -m "feat(performance): create DiamondTransactionTile and DiamondEconomySection"
```

---

## Task 5: Question Performance Section Widget

**Files:**
- Create: `lib/features/performance/widgets/question_performance_section.dart`

- [ ] **Step 1:** Soru performansi bolumu widget'ini olustur

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';

class QuestionPerformanceSection extends StatelessWidget {
  final QuestionAnalyticsResponse analytics;
  final VoidCallback? onBestQuestionTap;

  const QuestionPerformanceSection({
    super.key,
    required this.analytics,
    this.onBestQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = analytics.totals;
    final questions = analytics.questions;

    if (totals.totalSolveCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('question_performance'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              context.tr('no_solves_yet'),
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
            ),
          ),
        ],
      );
    }

    // Find hardest question (lowest success rate with at least 1 solve)
    final solvedQuestions = questions.where((q) => q.stats.solveCount > 0).toList();
    final hardestQuestion = solvedQuestions.isNotEmpty
        ? (solvedQuestions..sort((a, b) => a.stats.successRate.compareTo(b.stats.successRate))).first
        : null;

    // Best question
    final bestQuestion = totals.bestQuestionOrder != null
        ? questions.where((q) => q.orderNum == totals.bestQuestionOrder).firstOrNull
        : null;

    // Average solve time
    final avgTimes = solvedQuestions.map((q) => q.stats.avgTime).where((t) => t > 0);
    final overallAvgTime = avgTimes.isNotEmpty
        ? (avgTimes.reduce((a, b) => a + b) / avgTimes.length).round()
        : 0;

    // Difficulty distribution
    final diffCounts = <String, int>{};
    for (final q in questions) {
      diffCounts[q.difficultyBadge] = (diffCounts[q.difficultyBadge] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('question_performance'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Best + Hardest row
        if (bestQuestion != null)
          _QuestionHighlight(
            label: context.tr('best_question'),
            question: bestQuestion,
            color: context.appColors.secondary,
            onTap: onBestQuestionTap,
          ),
        if (hardestQuestion != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _QuestionHighlight(
            label: context.tr('hardest_question'),
            question: hardestQuestion,
            color: context.appColors.error,
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Avg solve time
        _InfoRow(label: context.tr('avg_solve_time'), value: '${overallAvgTime}s'),

        const SizedBox(height: AppSpacing.lg),

        // Difficulty distribution
        Text(
          context.tr('difficulty_distribution'),
          style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: diffCounts.entries.map((e) {
            return Chip(
              label: Text('${_difficultyLabel(context, e.key)} (${e.value})'),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _difficultyLabel(BuildContext context, String badge) {
    return switch (badge) {
      'easy' => context.tr('difficulty_easy'),
      'medium' => context.tr('difficulty_medium'),
      'hard' => context.tr('difficulty_hard'),
      'legendary' => context.tr('difficulty_legendary'),
      _ => context.tr('difficulty_unranked'),
    };
  }
}

class _QuestionHighlight extends StatelessWidget {
  final String label;
  final QuestionAnalyticsItem question;
  final Color color;
  final VoidCallback? onTap;

  const _QuestionHighlight({
    required this.label,
    required this.question,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Q${question.orderNum}: ${question.questionText}',
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '%${question.stats.successRate} • ${question.stats.greenEarned} elmas',
              style: theme.textTheme.bodySmall?.copyWith(color: context.appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```

- [ ] **Step 2:** `dart analyze` calistir
- [ ] **Step 3:** Commit

```bash
git add lib/features/performance/widgets/question_performance_section.dart
git commit -m "feat(performance): create QuestionPerformanceSection widget"
```

---

## Task 6: Dashboard Screen + Mixin

**Files:**
- Create: `lib/features/performance/screens/performance_dashboard_screen.dart`
- Create: `lib/features/performance/mixins/performance_dashboard_mixin.dart`

- [ ] **Step 1:** Mixin olustur

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/performance/screens/performance_dashboard_screen.dart';

mixin PerformanceDashboardMixin on ConsumerState<PerformanceDashboardScreen> {
  List<DiamondTransaction> recentTransactions = [];
  bool transactionsLoading = true;

  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.performanceDashboardOpened);
    Future.microtask(() {
      ref.read(questionAnalyticsProvider.notifier).fetchAnalytics();
      _loadTransactions();
    });
  }

  void disposeMixin() {}

  Future<void> _loadTransactions() async {
    final result = await ref.read(diamondProvider.notifier).fetchHistory();
    if (mounted) {
      setState(() {
        transactionsLoading = false;
        result.when(
          success: (data) => recentTransactions = data.items,
          failure: (_) => recentTransactions = [],
        );
      });
    }
  }

  void onViewAllDiamonds() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.performanceViewAllDiamonds);
    ref.read(navigationServiceProvider).push(RouteNames.diamonds);
  }

  void onBestQuestionTapped() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.performanceBestQuestionTapped);
    ref.read(navigationServiceProvider).push(RouteNames.questionAnalytics);
  }
}
```

- [ ] **Step 2:** Screen olustur

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/performance/mixins/performance_dashboard_mixin.dart';
import 'package:qulo_v2/features/performance/widgets/diamond_economy_section.dart';
import 'package:qulo_v2/features/performance/widgets/performance_summary_grid.dart';
import 'package:qulo_v2/features/performance/widgets/question_performance_section.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() => _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState extends ConsumerState<PerformanceDashboardScreen>
    with PerformanceDashboardMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(questionAnalyticsProvider);
    final analytics = analyticsState.valueOrNull;
    final user = ref.watch(userProvider).valueOrNull;

    return AppScaffold(
      title: context.tr('performance_dashboard'),
      isLoading: analyticsState is AsyncLoading,
      padding: EdgeInsets.zero,
      body: analytics == null
          ? Center(
              child: Text(
                context.tr('no_data_yet'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PerformanceSummaryGrid(totals: analytics.totals),
                  const SizedBox(height: AppSpacing.sectionGap),
                  DiamondEconomySection(
                    greenBalance: user?.greenDiamonds ?? 0,
                    purpleBalance: user?.purpleDiamonds ?? 0,
                    recentTransactions: recentTransactions,
                    onViewAll: onViewAllDiamonds,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  QuestionPerformanceSection(
                    analytics: analytics,
                    onBestQuestionTap: onBestQuestionTapped,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 3:** `dart analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/features/performance/
```

- [ ] **Step 4:** Commit

```bash
git add lib/features/performance/
git commit -m "feat(performance): create PerformanceDashboardScreen with mixin"
```

---

## Task 7: Profil Menusu + Profile Screen Callback

**Files:**
- Modify: `lib/features/profile/widgets/profile_menu_list.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Modify: `lib/features/profile/mixins/profile_screen_mixin.dart`

- [ ] **Step 1:** `ProfileMenuList`'e `onPerformance` callback + menu satiri ekle

Constructor'a `required this.onPerformance` ekle. Build'e yeni `ProfileMenuItem` ekle (Sorularim'dan sonra):

```dart
        ProfileMenuItem(
          iconPath: QIcons.icChart,
          title: context.tr('performance_analysis'),
          onTap: onPerformance,
        ),
```

- [ ] **Step 2:** `profile_screen_mixin.dart`'a navigasyon metodu ekle

```dart
  void openPerformance() {
    navigateTo(RouteNames.performance);
  }
```

- [ ] **Step 3:** `profile_screen.dart`'ta `ProfileMenuList`'e `onPerformance` callback'i gecir

```dart
                ProfileMenuList(
                  questionCount: user.questionCount,
                  onEditProfile: () => navigateTo(RouteNames.editProfile),
                  onQuestions: () => navigateTo(RouteNames.questions),
                  onPerformance: openPerformance,
                  onDiamonds: () => navigateTo(RouteNames.diamonds),
                  onSubscription: () => navigateTo(RouteNames.subscription),
                  onPassport: () => navigateTo(RouteNames.passport),
                ),
```

- [ ] **Step 4:** `dart analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/features/profile/
```

- [ ] **Step 5:** Commit

```bash
git add lib/features/profile/widgets/profile_menu_list.dart lib/features/profile/screens/profile_screen.dart lib/features/profile/mixins/profile_screen_mixin.dart
git commit -m "feat(performance): add Performance Analysis to profile menu"
```

---

## Task 8: Final Verification

- [ ] **Step 1:** Tum projeyi analyze et

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/
```

Beklenen: 0 hata

- [ ] **Step 2:** Commit gecmisini dogrula

```bash
git log --oneline -8
```

Beklenen: 7 commit (Task 1-7)

- [ ] **Step 3:** Manuel test plani

1. Sorular ekrani → sag ust analytics ikonu → QuestionAnalyticsScreen acilir (bug fix)
2. Profil ekrani → "Performans Analizi" menu satiri → dashboard acilir
3. Dashboard: 2x2 ozet kartlari gorunur (toplam cozulme, basari %, yesil kazanilan, mor harcanan)
4. Dashboard: Elmas ekonomisi bolumu — bakiye + son islemler
5. Dashboard: "Tumunu Gor" → Elmaslar sayfasina gider
6. Dashboard: Soru performansi — en iyi/en zor soru, ort sure, zorluk dagilimi
7. Dashboard: Hic sorusu olmayan kullanici → "Henuz veri yok" mesaji
