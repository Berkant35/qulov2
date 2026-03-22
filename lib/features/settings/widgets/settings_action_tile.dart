import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

class SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final Future<void> Function() onTap;

  const SettingsActionTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveTitleColor = titleColor ?? theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: SafeTapButton(
        onTap: onTap,
        builder: (context, isLoading, onTap) => ListTile(
          leading: isLoading
              ? const SizedBox(width: 24, height: 24, child: AppLoadingWidget.small())
              : Icon(icon, color: effectiveIconColor),
          title: Text(title, style: TextStyle(color: effectiveTitleColor)),
          onTap: onTap,
        ),
      ),
    );
  }
}
