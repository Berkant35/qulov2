import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/empty_state_view.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';

class DiscoverLocationError extends ConsumerWidget {
  final String error;

  const DiscoverLocationError({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMockError = error == 'LOCATION_MOCK_DETECTED';

    return EmptyStateView(
      icon: Icon(
        isMockError ? Icons.gps_off : Icons.location_off,
        size: 64,
        color: isMockError ? context.appColors.error : context.appColors.textHint,
      ),
      title: isMockError
          ? context.tr('location_mock_detected')
          : context.tr('location_required'),
      // Sahte konum uyarisinda ek aciklama yok — baslik zaten yeterince acik.
      message: isMockError ? null : context.tr('location_required_desc'),
      children: [
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
              backgroundColor:
                  isMockError ? context.appColors.error : context.appColors.primaryDark,
            ),
            child: Text(
              isMockError ? context.tr('location_retry') : context.tr('enable_location'),
            ),
          ),
        ),
      ],
    );
  }
}
