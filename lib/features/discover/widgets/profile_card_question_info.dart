import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/questions/widgets/difficulty_badge.dart';

/// Profil kartında soru sayısı + zorluk + kategori/dil çipleri
/// (`ProfileCard`'dan ayrıldı: özel alt widget ayrı dosyada, public).
class ProfileCardQuestionInfo extends StatelessWidget {
  final ProfileCardModel card;

  const ProfileCardQuestionInfo({super.key, required this.card});

  /// Kategori / dil çiplerinin yazısı kartın en küçük metni.
  static const _chipFontSize = 10.0;

  /// Yatay kategori şeridinin yüksekliği (tek çip satırı).
  static const _categoryRowHeight = 26.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = card.questionInfo;

    // Fallback: just show question count chip if no question_info
    if (info == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.appColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          context.tr('questions_count').replaceAll('{count}', '${card.questionCount}'),
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onScrim),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Question count + difficulty badge row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: context.appColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                context.tr('discover_questions_count').replaceAll('{count}', '${info.count}'),
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onScrim),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DifficultyBadge(difficulty: info.avgDifficulty),
          ],
        ),
        // Category chips
        if (info.categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: _categoryRowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: info.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final category = info.categories[index];
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.onScrim.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.onScrim.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      context.tr('question_category_$category'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onScrim,
                        fontSize: _chipFontSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Language chips
        if (info.languages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: info.languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + AppSpacing.xxs, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.onScrim.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.onScrim.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${AppConstants.localeFlagEmojis[lang] ?? ''} ${lang.toUpperCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onScrim,
                  fontSize: _chipFontSize,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}
