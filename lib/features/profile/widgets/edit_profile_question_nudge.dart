import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class EditProfileQuestionNudge extends ConsumerWidget {
  const EditProfileQuestionNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).valueOrNull;
    if (user == null || user.questionCount >= AppConstants.minQuestions) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.appColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.appColors.primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr('question_nudge_edit_hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () =>
                  ref.read(navigationServiceProvider).go(RouteNames.questions),
              child: Text(context.tr('question_nudge_go_questions')),
            ),
          ],
        ),
      ),
    );
  }
}
