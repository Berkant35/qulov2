import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/questions/widgets/difficulty_badge.dart';

class ProfileQuestionInfo extends StatelessWidget {
  final QuestionInfoModel questionInfo;
  const ProfileQuestionInfo({super.key, required this.questionInfo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('questions'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Question count + difficulty badge
          Row(
            children: [
              _InfoChip(
                icon: Icons.quiz_outlined,
                label: context
                    .tr('discover_questions_count')
                    .replaceAll('{count}', '${questionInfo.count}'),
              ),
              const SizedBox(width: AppSpacing.sm),
              DifficultyBadge(difficulty: questionInfo.avgDifficulty),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Categories
          if (questionInfo.categories.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: questionInfo.categories
                  .map((c) => _CategoryChip(
                        label: context.tr('question_category_$c'),
                      ))
                  .toList(),
            ),

          // Languages
          if (questionInfo.languages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: questionInfo.languages
                  .map((l) => _LanguageChip(locale: l))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: context.appColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.appColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String locale;
  const _LanguageChip({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '${AppConstants.localeFlagEmojis[locale] ?? ''} ${locale.toUpperCase()}',
        style: TextStyle(
          color: context.appColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}
