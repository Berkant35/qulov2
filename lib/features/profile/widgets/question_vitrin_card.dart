import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class QuestionVitrinCard extends ConsumerStatefulWidget {
  const QuestionVitrinCard({super.key});

  @override
  ConsumerState<QuestionVitrinCard> createState() => _QuestionVitrinCardState();
}

class _QuestionVitrinCardState extends ConsumerState<QuestionVitrinCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(questionAnalyticsProvider.notifier).fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(questionAnalyticsProvider);
    final theme = Theme.of(context);

    return analyticsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (analytics) {
        if (analytics == null) return const SizedBox.shrink();

        final totals = analytics.totals;
        if (totals.totalSolveCount == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => ref.read(navigationServiceProvider).go(RouteNames.questionAnalytics),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: context.appColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('profile_vitrin_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    // Total solves
                    Expanded(
                      child: _VitrinStat(
                        icon: Icon(
                          Icons.people_outline,
                          size: 20,
                          color: context.appColors.primary,
                        ),
                        value: context.fmt.integer(totals.totalSolveCount),
                        label: context.tr('profile_vitrin_solves'),
                      ),
                    ),
                    // Success rate
                    Expanded(
                      child: _VitrinStat(
                        icon: Icon(
                          Icons.trending_up,
                          size: 20,
                          color: context.appColors.warning,
                        ),
                        value: '%${totals.overallSuccessRate}',
                        label: context.tr('profile_vitrin_success'),
                      ),
                    ),
                    // Green earned
                    Expanded(
                      child: _VitrinStat(
                        icon: const DiamondIcon.green(size: 20, showGlow: false),
                        value: '${totals.totalGreenEarned}',
                        label: context.tr('profile_vitrin_green'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VitrinStat extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const _VitrinStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
