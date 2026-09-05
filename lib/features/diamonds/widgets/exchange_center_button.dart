import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

/// Elmas ekranindan takas merkezine goturen kart butonu.
class ExchangeCenterButton extends StatelessWidget {
  const ExchangeCenterButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.cardPadding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.secondary.withValues(alpha: 0.15),
              colors.primary.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: colors.secondary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.secondary.withValues(alpha: 0.3),
                    colors.secondary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: AppIcon(
                  QIcons.bolt,
                  color: colors.secondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('exchange_title'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('exchange_subtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withValues(alpha: 0.2),
              ),
              child: QIcon(
                QIcons.icChevronRight,
                color: colors.textPrimary.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
