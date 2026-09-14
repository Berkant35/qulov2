import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Mesaj baloncugunun altindaki saat — soru ve normal mesajda ayni gorunum.
class MessageTimestamp extends StatelessWidget {
  final String text;
  final double topPadding;

  const MessageTimestamp({super.key, required this.text, this.topPadding = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: AppSpacing.xs),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
