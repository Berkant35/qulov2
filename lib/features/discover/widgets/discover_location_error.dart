import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiscoverLocationError extends ConsumerWidget {
  final String error;

  const DiscoverLocationError({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('location_required'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('location_required_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                  final manager = ref.read(locationManagerProvider);
                  if (error == 'LOCATION_SERVICE_DISABLED') {
                    await manager.openLocationSettings();
                  } else {
                    await manager.openAppSettings();
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                child: Text(context.tr('enable_location')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
