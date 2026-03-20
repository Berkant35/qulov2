import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';

class DiscoverLocationError extends ConsumerWidget {
  final String error;

  const DiscoverLocationError({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMockError = error == 'LOCATION_MOCK_DETECTED';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMockError ? Icons.gps_off : Icons.location_off,
              size: 64,
              color: isMockError ? AppColors.error : context.appColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isMockError
                  ? context.tr('location_mock_detected')
                  : context.tr('location_required'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (!isMockError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('location_required_desc'),
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                  if (isMockError) {
                    ref.read(locationProvider.notifier).getCurrentLocation();
                  } else {
                    final manager = ref.read(locationManagerProvider);
                    if (error == 'LOCATION_SERVICE_DISABLED') {
                      await manager.openLocationSettings();
                    } else {
                      await manager.openAppSettings();
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isMockError ? AppColors.error : context.appColors.primaryDark,
                ),
                child: Text(
                  isMockError
                      ? context.tr('location_retry')
                      : context.tr('enable_location'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
