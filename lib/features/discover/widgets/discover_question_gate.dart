import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/question_progress_bar.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/discover/widgets/profile_card.dart';

class DiscoverQuestionGate extends ConsumerWidget {
  final int questionCount;
  final int nudgeCount;
  final ProfileCardModel? firstCard;

  const DiscoverQuestionGate({
    super.key,
    required this.questionCount,
    required this.nudgeCount,
    this.firstCard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Stack(
        children: [
          if (firstCard != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: ProfileCard(card: firstCard!),
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.71),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: QuestionProgressBar(questionCount: questionCount),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (nudgeCount >= 2)
                    QuestionGateEasyModeNudge(ref: ref)
                  else
                    QuestionGateAddButton(ref: ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionGateEasyModeNudge extends StatelessWidget {
  final WidgetRef ref;

  const QuestionGateEasyModeNudge({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                QIcon(QIcons.icWand, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr('nudge_easy_mode_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => ref.read(navigationServiceProvider).push(
            RouteNames.questionEasyMode,
          ),
          icon: QIcon(QIcons.icWand, color: theme.colorScheme.onPrimary, size: 18),
          label: Text(context.tr('nudge_easy_mode_button')),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
          icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onSurfaceVariant, size: 16),
          label: Text(
            context.tr('question_nudge_add_button'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class QuestionGateAddButton extends StatelessWidget {
  final WidgetRef ref;

  const QuestionGateAddButton({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
      icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onPrimary, size: 18),
      label: Text(context.tr('question_nudge_add_button')),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      ),
    );
  }
}
