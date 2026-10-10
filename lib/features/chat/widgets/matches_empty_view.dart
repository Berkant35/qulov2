import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Eşleşme yokken: çekerek yenilenebilen boş durum.
class MatchesEmptyView extends StatelessWidget {
  const MatchesEmptyView({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Icon(Icons.favorite_border, size: 64, color: theme.hintColor),
          const SizedBox(height: AppSpacing.lg),
          Center(child: Text(context.tr('no_matches'), style: theme.textTheme.titleMedium)),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              context.tr('start_swiping'),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
