import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class SocialLoginButtons extends StatelessWidget {
  static const double _buttonHeight = 52;

  final bool isLoading;
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;

  const SocialLoginButtons({
    super.key,
    required this.isLoading,
    required this.onGooglePressed,
    required this.onApplePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // "veya" divider
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                context.tr('or'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Google button
        SizedBox(
          width: double.infinity,
          height: _buttonHeight,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onGooglePressed,
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: Text(context.tr('sign_in_with_google')),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),

        // Apple button (iOS only)
        if (Platform.isIOS) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: _buttonHeight,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onApplePressed,
              icon: const Icon(Icons.apple, size: 28),
              label: Text(context.tr('sign_in_with_apple')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.onSurface,
                foregroundColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
