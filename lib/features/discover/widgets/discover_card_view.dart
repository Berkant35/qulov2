import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/circle_icon_button.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/locked_feature_button.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/discover/widgets/profile_card.dart';

class DiscoverCardView extends ConsumerWidget {
  final ProfileCardModel card;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  const DiscoverCardView({
    super.key,
    required this.card,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverState = ref.watch(discoverProvider).valueOrNull;
    final canUndo = discoverState?.canUndo ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Expanded(child: ProfileCard(card: card)),
          DiscoverSolveButton(
            label: context.tr('solve_questions'),
            onTap: () => _navigateToQuiz(ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          DiscoverActionButtons(
            canUndo: canUndo,
            onUndo: () => _handleUndo(context, ref),
            onReject: () async {
              onSwipeLeft();
              final result = await ref.read(discoverProvider.notifier).swipe(
                targetId: card.userId,
                action: 'REJECT',
              );
              result.when(
                success: (_) {},
                failure: (f) {
                  if (f is ServerFailure && f.code == 'DAILY_LIMIT_REACHED') {
                    PaywallBottomSheetContent.show(ref, trigger: 'swipe_limit');
                  }
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _navigateToQuiz(WidgetRef ref) async {
    onSwipeRight();
    final result = await ref.read(discoverProvider.notifier).swipe(
      targetId: card.userId,
      action: 'LIKE',
    );
    result.when(
      success: (_) {
        ref.read(navigationServiceProvider).push(
          RouteNames.quiz,
          params: {'targetId': card.userId},
        );
      },
      failure: (f) {
        if (f is ServerFailure && f.code == 'DAILY_LIMIT_REACHED') {
          PaywallBottomSheetContent.show(ref, trigger: 'swipe_limit');
        }
      },
    );
  }

  void _handleUndo(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(discoverProvider.notifier).undoSwipe();
    result.when(
      success: (_) {
        ref.invalidate(dailyStatsProvider);
      },
      failure: (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('undo_limit_reached'))),
          );
        }
      },
    );
  }
}

class DiscoverSolveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DiscoverSolveButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiscoverActionButtons extends ConsumerWidget {
  final VoidCallback onReject;
  final VoidCallback onUndo;
  final bool canUndo;

  const DiscoverActionButtons({
    super.key,
    required this.onReject,
    required this.onUndo,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyStats = ref.watch(dailyStatsProvider).valueOrNull;
    final undosUsed = dailyStats?.dailyUndosUsed ?? 0;
    final undosLimit = dailyStats?.dailyUndosLimit ?? 0;
    final isUnlimited = dailyStats?.isUndoUnlimited ?? false;
    final hasUndoRight = isUnlimited || undosLimit > 0;
    final undosRemaining = isUnlimited ? -1 : (undosLimit - undosUsed).clamp(0, undosLimit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LockedFeatureButton(
              isLocked: !hasUndoRight,
              trigger: 'undo_locked',
              child: CircleIconButton(
                iconPath: QIcons.icArrowLeft,
                iconColor: canUndo ? AppColors.warning : AppColors.textHint,
                backgroundColor: Theme.of(context).colorScheme.surface,
                borderColor: canUndo
                    ? AppColors.warning
                    : AppColors.textHint.withValues(alpha: 0.3),
                size: 44,
                onTap: canUndo ? onUndo : () {},
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasUndoRight
                  ? (isUnlimited ? '∞' : '$undosRemaining')
                  : context.tr('undo'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: hasUndoRight
                    ? (canUndo ? AppColors.warning : AppColors.textHint)
                    : AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),
        CircleIconButton(
          iconPath: QIcons.icX,
          iconColor: AppColors.error,
          backgroundColor: Theme.of(context).colorScheme.surface,
          borderColor: AppColors.error,
          onTap: onReject,
        ),
      ],
    );
  }
}
