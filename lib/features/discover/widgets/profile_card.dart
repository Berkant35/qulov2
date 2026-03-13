import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/questions/widgets/difficulty_badge.dart';

class ProfileCard extends StatelessWidget {
  final ProfileCardModel card;
  const ProfileCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = card.photos?.isNotEmpty == true ? card.photos!.first : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
          else
            Container(color: theme.colorScheme.surface, child: Center(child: QIcon(QIcons.icUser, color: theme.hintColor, size: 80))),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${card.name ?? context.tr('unknown')}, ${card.age ?? ''}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (card.isBoosted) ...[
                      const SizedBox(width: AppSpacing.sm),
                      QIcon(QIcons.icZap, color: AppColors.warning, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (card.city != null)
                  Row(
                    children: [
                      QIcon(QIcons.icMapPin, color: Colors.white70, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${card.city} • ${card.distanceKm < 1.0 ? context.tr('nearby') : '${card.distanceKm.toStringAsFixed(1)} km'}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                if (card.relationshipGoal != null && card.relationshipGoal != 'NOT_SURE')
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      _relationshipGoalLabel(context, card.relationshipGoal),
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                // ─── Question Info Section ───
                _buildQuestionInfoSection(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInfoSection(BuildContext context, ThemeData theme) {
    final info = card.questionInfo;

    // Fallback: just show question count chip if no question_info
    if (info == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          context.tr('questions_count').replaceAll('{count}', '${card.questionCount}'),
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
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
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                context.tr('discover_questions_count').replaceAll('{count}', '${info.count}'),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
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
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: info.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final category = info.categories[index];
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      context.tr('question_category_$category'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${AppConstants.localeFlagEmojis[lang] ?? ''} ${lang.toUpperCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  String _relationshipGoalLabel(BuildContext context, String? goal) {
    return switch (goal) {
      'SERIOUS' => context.tr('serious_relationship'),
      'FRIENDSHIP' => context.tr('friendship'),
      _ => context.tr('not_sure'),
    };
  }
}
