import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/diamonds/widgets/monthly_benefits_card.dart';

class DiamondsMonthlyBenefitsSection extends ConsumerWidget {
  const DiamondsMonthlyBenefitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ? () => ref.read(navigationServiceProvider).go(RouteNames.subscription)
                : null,
          ),
        );
      },
    );
  }
}
