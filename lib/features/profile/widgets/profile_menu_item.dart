import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class ProfileMenuItem extends StatelessWidget {
  final String? iconPath;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final bool showBadge;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    this.iconPath,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.showBadge = false,
    required this.onTap,
  }) : assert(iconPath != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget ?? QIcon(iconPath!, color: AppColors.primary, size: 24),
            if (showBadge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error))
            : null,
        trailing: QIcon(QIcons.icChevronRight, color: theme.hintColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
