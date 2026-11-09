import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/ink_surface.dart';

/// Soru oluşturma adım 2'deki ayar anahtarı (eşleşmeyi bitir, sohbet kilidi, güç engeli).
class ChatQuestionSettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final ValueChanged<bool> onChanged;

  const ChatQuestionSettingSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.icon,
    this.badge,
    this.badgeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkSurface(
      color: context.appColors.surfaceElevated,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: activeColor,
        activeTrackColor: activeColor.withValues(alpha: 0.4),
        secondary: Icon(icon, color: value ? activeColor : context.appColors.textHint),
        title: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: value ? activeColor : context.appColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: (badgeColor ?? activeColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badge!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: badgeColor ?? activeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    DiamondIcon.purple(size: 12, showGlow: false),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
      ),
    );
  }
}
