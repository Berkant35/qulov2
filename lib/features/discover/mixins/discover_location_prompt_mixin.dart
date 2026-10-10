import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/discover/models/location_prompt_content.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';

/// Konum yokken Discover'daki istem kartının mantığı. Kart hata ekranı değil:
/// önce neden gerektiğini anlatır, sistem istemini kullanıcı dokununca açar.
/// İzin gelince desteyi `DiscoverScreenMixin.listenLocationRecovery` yükler.
mixin DiscoverLocationPromptMixin {
  LocationPromptContent promptFor(String error) => switch (error) {
        LocationErrors.mockDetected => const LocationPromptContent(
            titleKey: 'location_mock_detected',
            messageKey: null,
            ctaKey: 'location_retry',
            action: LocationPromptAction.requestPermission,
            isMock: true,
          ),
        LocationErrors.serviceDisabled => const LocationPromptContent(
            titleKey: 'location_prompt_title',
            messageKey: 'location_prompt_service_desc',
            ctaKey: 'enable_location',
            action: LocationPromptAction.openLocationSettings,
          ),
        // iOS'ta bir kez reddedilen izin bir daha sorulmaz; Android'de
        // "bir daha sorma" sonrası da aynı — tek yol Ayarlar.
        LocationErrors.permissionDeniedForever => const LocationPromptContent(
            titleKey: 'location_prompt_title',
            messageKey: 'location_prompt_settings_desc',
            ctaKey: 'open_settings',
            action: LocationPromptAction.openAppSettings,
          ),
        _ => const LocationPromptContent(
            titleKey: 'location_prompt_title',
            messageKey: 'location_prompt_desc',
            ctaKey: 'location_prompt_allow',
            action: LocationPromptAction.requestPermission,
          ),
      };

  void logLocationPromptShown(String error) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverLocationPromptShow,
      params: {AnalyticsEvents.paramReason: error},
    );
  }

  Future<void> onLocationPromptTap(WidgetRef ref, String error) async {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverLocationPromptTap,
      params: {AnalyticsEvents.paramReason: error},
    );
    final manager = ref.read(locationManagerProvider);
    switch (promptFor(error).action) {
      case LocationPromptAction.requestPermission:
        await ref.read(locationProvider.notifier).getCurrentLocation();
      case LocationPromptAction.openAppSettings:
        await manager.openAppSettings();
      case LocationPromptAction.openLocationSettings:
        await manager.openLocationSettings();
    }
  }
}
