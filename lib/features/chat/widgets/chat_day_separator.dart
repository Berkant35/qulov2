import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ChatDaySeparator extends StatelessWidget {
  final DateTime day;

  const ChatDaySeparator({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (day == today) {
      label = 'Bugun';
    } else if (day == yesterday) {
      label = 'Dun';
    } else {
      label =
          '${day.day}.${day.month.toString().padLeft(2, '0')}.${day.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
