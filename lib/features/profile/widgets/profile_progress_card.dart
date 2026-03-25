import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/widgets/badge_bar.dart';
import 'package:qulo_v2/features/profile/widgets/profile_completion_bar.dart';

class ProfileProgressCard extends StatelessWidget {
  const ProfileProgressCard({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onNavigate,
    required this.onClaimReward,
  });

  final UserModel user;
  final VoidCallback onEditProfile;
  final void Function(String route) onNavigate;
  final Future<void> Function(String level) onClaimReward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          ProfileCompletionBar(
            completionPercent: user.profileCompletion,
            onTap: onEditProfile,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              color: theme.dividerColor.withValues(alpha: 0.3),
              height: 1,
            ),
          ),
          BadgeBar(
            user: user,
            onNavigate: onNavigate,
            onClaimReward: onClaimReward,
          ),
        ],
      ),
    );
  }
}
