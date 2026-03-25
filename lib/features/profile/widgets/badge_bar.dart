import 'package:flutter/material.dart';

import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/user_model.dart';

// ─── Badge Level ───

enum BadgeLevel { none, bronze, silver, gold }

// ─── Checklist Item ───

class ProfileChecklistItem {
  final String label;
  final bool completed;
  final String? route;

  const ProfileChecklistItem({
    required this.label,
    required this.completed,
    this.route,
  });
}

// ─── Badge Info ───

class BadgeInfo {
  final BadgeLevel level;
  final String name;
  final String iconPath;
  final Color color;
  final double progress;
  final List<ProfileChecklistItem> checklist;
  final BadgeLevel? nextLevel;
  final int? percentToNext;

  const BadgeInfo({
    required this.level,
    required this.name,
    required this.iconPath,
    required this.color,
    required this.progress,
    this.checklist = const [],
    this.nextLevel,
    this.percentToNext,
  });
}

// ─── Badge Calculation ───

BadgeInfo calculateBadgeInfo(BuildContext context, UserModel user) {
  final pct = user.profileCompletion.clamp(0, 100);
  final progress = pct / 100;

  final BadgeLevel level;
  final String name;
  final String iconPath;
  final Color color;
  final BadgeLevel? nextLevel;
  final int? percentToNext;

  if (pct >= 85) {
    level = BadgeLevel.gold;
    name = context.tr('badge_master');
    iconPath = QIcons.icBadgeGold;
    color = AppColors.gold;
    nextLevel = null;
    percentToNext = null;
  } else if (pct >= 60) {
    level = BadgeLevel.silver;
    name = context.tr('badge_popular');
    iconPath = QIcons.icBadgeSilver;
    color = AppColors.silver;
    nextLevel = BadgeLevel.gold;
    percentToNext = 85 - pct;
  } else if (pct >= 30) {
    level = BadgeLevel.bronze;
    name = context.tr('badge_rookie');
    iconPath = QIcons.icBadgeBronze;
    color = AppColors.bronze;
    nextLevel = BadgeLevel.silver;
    percentToNext = 60 - pct;
  } else {
    level = BadgeLevel.none;
    name = context.tr('badge_no_badge');
    iconPath = QIcons.icBadgeBronze;
    color = Theme.of(context).hintColor;
    nextLevel = BadgeLevel.bronze;
    percentToNext = 30 - pct;
  }

  // Build checklist — ALL profile requirements
  final photos = user.photos ?? [];
  final checklist = <ProfileChecklistItem>[
    ProfileChecklistItem(
      label: context.tr('checklist_photos'),
      completed: photos.length >= 3,
      route: 'editProfile',
    ),
    ProfileChecklistItem(
      label: context.tr('checklist_bio'),
      completed: user.bio != null && user.bio!.isNotEmpty,
      route: 'editProfile',
    ),
    ProfileChecklistItem(
      label: context.tr('checklist_details'),
      completed: user.details?.job != null && user.details?.zodiac != null,
      route: 'editProfile',
    ),
    ProfileChecklistItem(
      label: context.tr('checklist_questions'),
      completed: user.questionCount >= AppConstants.minQuestions,
      route: 'questions',
    ),
    ProfileChecklistItem(
      label: context.tr('checklist_relationship'),
      completed: user.relationshipGoal != null && user.relationshipGoal != 'NOT_SURE',
      route: 'editProfile',
    ),
  ];

  return BadgeInfo(
    level: level,
    name: name,
    iconPath: iconPath,
    color: color,
    progress: progress,
    checklist: checklist,
    nextLevel: nextLevel,
    percentToNext: percentToNext,
  );
}

// ─── BadgeBar Widget ───

class BadgeBar extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(String level)? onClaimReward;
  final void Function(String route)? onNavigate;

  const BadgeBar({
    super.key,
    required this.user,
    this.onClaimReward,
    this.onNavigate,
  });

  bool _canClaimReward(UserModel user, String levelStr, int threshold) {
    return user.profileCompletion >= threshold &&
        !user.badgeRewardsClaimed.contains(levelStr);
  }

  @override
  Widget build(BuildContext context) {
    final info = calculateBadgeInfo(context, user);
    final pct = user.profileCompletion.clamp(0, 100);

    final canClaimSilver = _canClaimReward(user, 'SILVER', 60);
    final canClaimGold = _canClaimReward(user, 'GOLD', 85);
    final showClaim = canClaimGold || canClaimSilver;
    final claimLevel = canClaimGold ? 'GOLD' : 'SILVER';

    final incompleteItems = info.checklist.where((c) => !c.completed).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: info.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header Row ───
          Row(
            children: [
              QIcon(info.iconPath, size: 20, color: info.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    color: info.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '%$pct',
                style: TextStyle(
                  color: info.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ─── Progress Bar ───
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 6,
              backgroundColor: context.appColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(info.color),
            ),
          ),

          // ─── Checklist ───
          if (incompleteItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...incompleteItems.map((item) => _ChecklistRow(
              item: item,
              color: info.color,
              onTap: item.route != null && onNavigate != null
                  ? () => onNavigate!(item.route!)
                  : null,
            )),
          ],

          // ─── All Complete ───
          if (incompleteItems.isEmpty && pct >= 85) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: info.color),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.tr('checklist_all_done'),
                  style: TextStyle(
                    color: info.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // ─── Discover Warning ───
          if (info.level == BadgeLevel.none) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: context.appColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr('badge_discover_warning'),
                    style: TextStyle(
                      color: context.appColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ─── Claim Button ───
          if (showClaim && onClaimReward != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onClaimReward!(claimLevel),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: info.color),
                  foregroundColor: info.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                icon: const DiamondIcon.purple(size: 18, showGlow: false),
                label: Text(
                  context.tr('badge_claim_reward'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Checklist Row Widget ───

class _ChecklistRow extends StatelessWidget {
  final ProfileChecklistItem item;
  final Color color;
  final VoidCallback? onTap;

  const _ChecklistRow({
    required this.item,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              item.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: item.completed ? context.appColors.secondary : theme.colorScheme.outline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: item.completed
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  fontSize: 13,
                  decoration: item.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!item.completed && onTap != null)
              Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
