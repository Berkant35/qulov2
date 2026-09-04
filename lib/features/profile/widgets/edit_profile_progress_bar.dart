import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class EditProfileProgressBar extends StatelessWidget {
  final int completion;
  final String milestoneMessage;

  const EditProfileProgressBar({
    super.key,
    required this.completion,
    required this.milestoneMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = completion.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profil Tamamlama',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              context.fmt.percent(percentage),
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.appColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(context.appColors.primary),
          ),
        ),
        if (milestoneMessage.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            milestoneMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
