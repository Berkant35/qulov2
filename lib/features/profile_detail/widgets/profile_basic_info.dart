import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/utils/location_format.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';

class ProfileBasicInfo extends StatelessWidget {
  final PublicProfileModel profile;
  final bool showOnlineStatus;
  final bool showDistance;

  const ProfileBasicInfo({
    super.key,
    required this.profile,
    this.showOnlineStatus = false,
    this.showDistance = true,
  });

  @override
  Widget build(BuildContext context) {
    // Sehir yokken de mesafe gorunur; mesafe bilinmiyorsa (null) yazilmaz.
    final locationText = locationLine(
      city: profile.city,
      distanceKm: showDistance ? profile.distanceKm : null,
      nearbyLabel: context.tr('nearby'),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Age + Boost
          Row(
            children: [
              Flexible(
                child: Text(
                  '${profile.name ?? ''}, ${profile.age ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isBoosted) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.appColors.warning.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    QIcons.bolt,
                    color: context.appColors.warning,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Location + Distance
          if (locationText != null)
            Row(
              children: [
                AppIcon(
                  QIcons.mapPin,
                  size: 16,
                  color: context.appColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  locationText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),

          // Relationship goal + Online status
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (profile.relationshipGoal != null)
                _RelationshipGoalChip(goal: profile.relationshipGoal!),
              if (showOnlineStatus && profile.isOnline != null)
                _OnlineStatusChip(
                  isOnline: profile.isOnline!,
                  lastSeen: profile.lastSeen,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelationshipGoalChip extends StatelessWidget {
  final String goal;
  const _RelationshipGoalChip({required this.goal});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (goal) {
      'SERIOUS' => (Icons.favorite, context.appColors.error, context.tr('serious_relationship')),
      'FRIENDSHIP' => (Icons.people, context.appColors.secondary, context.tr('friendship')),
      _ => (Icons.help_outline, context.appColors.warning, context.tr('not_sure')),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineStatusChip extends StatelessWidget {
  final bool isOnline;
  final String? lastSeen;
  const _OnlineStatusChip({required this.isOnline, this.lastSeen});

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.appColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.tr('online'),
            style: TextStyle(
              color: context.appColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (lastSeen != null) {
      final dt = DateTime.tryParse(lastSeen!);
      if (dt != null) {
        final diff = DateTime.now().toUtc().difference(dt);
        final label = diff.inMinutes < 60
            ? '${diff.inMinutes}m'
            : diff.inHours < 24
                ? '${diff.inHours}h'
                : '${diff.inDays}d';
        return Text(
          '${context.tr('last_seen')} $label',
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: 12,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
