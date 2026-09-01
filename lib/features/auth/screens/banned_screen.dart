import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

class BannedScreen extends ConsumerWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // AppScaffold zaten SafeArea + Center + padding + app background sağlar.
    return AppScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gpp_bad,
            size: 80,
            color: context.appColors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('account_banned_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('account_banned_message'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'info@socrepho.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }
}
