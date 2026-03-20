import 'package:flutter/material.dart';

import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/user_model.dart';

// ─── Badge Level ───

enum BadgeLevel { none, bronze, silver, gold }

// ─── Badge Info ───

class BadgeInfo {
  final BadgeLevel level;
  final String name;
  final String iconPath;
  final Color color;
  final double progress;
  final String? hint;
  final BadgeLevel? nextLevel;
  final int? percentToNext;

  const BadgeInfo({
    required this.level,
    required this.name,
    required this.iconPath,
    required this.color,
    required this.progress,
    this.hint,
    this.nextLevel,
    this.percentToNext,
  });
}

// ─── Badge Calculation ───

BadgeInfo calculateBadgeInfo(BuildContext context, UserModel user) {
  final pct = user.profileCompletion.clamp(0, 100);
  final progress = pct / 100;

  // Determine current level
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

  // Determine hint
  String? hint;
  if (level != BadgeLevel.gold) {
    final photos = user.photos ?? [];
    if (photos.length < 3) {
      hint = context.tr('hint_add_photos');
    } else if (user.bio == null || user.bio!.isEmpty) {
      hint = context.tr('hint_add_bio');
    } else if (user.details?.job == null) {
      hint = context.tr('hint_add_job');
    } else {
      hint = context.tr('hint_add_details');
    }
  }

  return BadgeInfo(
    level: level,
    name: name,
    iconPath: iconPath,
    color: color,
    progress: progress,
    hint: hint,
    nextLevel: nextLevel,
    percentToNext: percentToNext,
  );
}

// ─── BadgeBar Widget ───

class BadgeBar extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(String level)? onClaimReward;

  const BadgeBar({
    super.key,
    required this.user,
    this.onClaimReward,
  });

  bool _canClaimReward(UserModel user, String levelStr, int threshold) {
    return user.profileCompletion >= threshold &&
        !user.badgeRewardsClaimed.contains(levelStr);
  }

  @override
  Widget build(BuildContext context) {
    final info = calculateBadgeInfo(context, user);
    final pct = user.profileCompletion.clamp(0, 100);

    // Check claimable rewards
    final canClaimSilver = _canClaimReward(user, 'SILVER', 60);
    final canClaimGold = _canClaimReward(user, 'GOLD', 85);
    final showClaim = canClaimGold || canClaimSilver;
    final claimLevel = canClaimGold ? 'GOLD' : 'SILVER';

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
          // ─── Header Row: badge icon + name (left) | percentage (right) ───
          Row(
            children: [
              QIcon(
                info.iconPath,
                size: 20,
                color: info.color,
              ),
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

          // ─── Hint Text ───
          if (info.hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              info.hint!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],

          // ─── Discover Warning ───
          if (info.level == BadgeLevel.none) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr('badge_discover_warning'),
                    style: const TextStyle(
                      color: AppColors.warning,
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
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                ),
                icon: const DiamondIcon.purple(size: 18, showGlow: false),
                label: Text(
                  context.tr('badge_claim_reward'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
