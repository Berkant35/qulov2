import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Kilitli (salt okunur) cinsiyet satırı + "değişiklik talep et" aksiyonu.
class EditProfileGenderRow extends StatelessWidget {
  final String genderLabelKey;
  final VoidCallback onRequestChange;

  const EditProfileGenderRow({
    super.key,
    required this.genderLabelKey,
    required this.onRequestChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('gender'),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.appColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr(genderLabelKey),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onRequestChange, child: Text(context.tr('gender_change_request'))),
      ],
    );
  }
}
