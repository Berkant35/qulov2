import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class ProfileSaveSuccessSheet extends StatelessWidget {
  final VoidCallback? onPreview;

  const ProfileSaveSuccessSheet({super.key, this.onPreview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.appColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: context.appColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('profile_updated_success'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (onPreview != null)
            AppButton(
              label: context.tr('preview_profile'),
              onPressed: onPreview!,
              icon: Icons.visibility,
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
