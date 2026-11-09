import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/discover/models/location_prompt_content.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/discover/utils/discover_location_gate.dart';
import 'package:qulo_v2/routing/route_names.dart';

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
            offersCity: false,
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

  /// Konum vermeden devam: şehir seç (sunucu şehir merkezini konum yazar).
  void openCityPicker(WidgetRef ref, String error) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverLocationPromptTap,
      params: {AnalyticsEvents.paramReason: error, AnalyticsEvents.paramAction: cityPickerAction},
    );
    ref.read(navigationServiceProvider).push(RouteNames.cityPicker);
  }

  /// Analitikte istem kartının "şehir seç" dokunuşu (`action` parametresi).
  static const cityPickerAction = 'city_picker';

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
    final location = ref.read(locationProvider.notifier);
    final discover = ref.read(discoverProvider.notifier);
    switch (promptFor(error).action) {
      case LocationPromptAction.requestPermission:
        await location.getCurrentLocation();
        // Sunucuda konum yoktu ama cihazda vardı: konum "hazır hale gelmedi",
        // `listenLocationRecovery` desteyi yüklemez — burada yeniden çekilir.
        if (error == discoverLocationMissingCode && location.hasUsableLocation) {
          await discover.loadCards();
        }
      case LocationPromptAction.openAppSettings:
        await manager.openAppSettings();
      case LocationPromptAction.openLocationSettings:
        await manager.openLocationSettings();
    }
  }
}
