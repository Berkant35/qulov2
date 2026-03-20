import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';

class GreenEarnedBanner extends StatelessWidget {
  final int greenEarned;

  const GreenEarnedBanner({super.key, required this.greenEarned});

  @override
  Widget build(BuildContext context) {
    if (greenEarned <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DiamondIcon.green(size: 18, showGlow: false),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              context
                  .tr('analytics_green_question')
                  .replaceAll('{n}', '$greenEarned'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.appColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
