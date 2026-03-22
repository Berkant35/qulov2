import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/locale_provider.dart';

class SettingsLanguageTile extends ConsumerWidget {
  final VoidCallback onTap;

  const SettingsLanguageTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: Icon(Icons.language, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          context.tr('language'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          '${AppConstants.localeFlagEmojis[locale.languageCode] ?? ''} ${context.tr('locale_${locale.languageCode}')}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
