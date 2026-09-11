import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

/// Kurulum ekraninda sorular hazir degilken "hizli ata" kisayolu.
/// `onTap` null ise (islem suruyor) dokunus devre disi.
class SetupHurryHintCard extends StatelessWidget {
  final VoidCallback? onTap;

  const SetupHurryHintCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AppIcon(QIcons.bolt, filled: true, size: 22, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.tr('setup_hint'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              QIcon(
                QIcons.icChevronRight,
                size: 18,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
