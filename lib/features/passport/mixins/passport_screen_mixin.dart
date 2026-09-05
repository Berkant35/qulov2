import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/teleport_service.dart';
import 'package:qulo_v2/features/passport/constants/popular_cities.dart';
import 'package:qulo_v2/features/passport/screens/passport_screen.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin PassportScreenMixin on ConsumerState<PassportScreen> {
  final analytics = AnalyticsManager.instance;
  bool isChangingCity = false;

  void initMixin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final passport = ref.read(passportProvider);
      analytics.logEvent(AnalyticsEvents.passportScreenView, params: {
        AnalyticsEvents.paramIsActive: passport.isActive ? 1 : 0,
      });
    });
  }

  void disposeMixin() {}

  void navigateToConfirm({
    required String city,
    required String country,
    required String flag,
    required double lat,
    required double lng,
  }) {
    ref.read(navigationServiceProvider).push(
      RouteNames.mapConfirm,
      extra: {'cityName': city, 'country': country, 'flag': flag, 'lat': lat, 'lng': lng},
    );
  }

  void onSearchCitySelected(TeleportCity city) {
    analytics.logEvent(AnalyticsEvents.passportCitySearch, params: {
      AnalyticsEvents.paramDestinationCity: city.name,
    });
    final country = city.fullName.contains(',')
        ? city.fullName.split(',').last.trim()
        : city.fullName;
    navigateToConfirm(city: city.name, country: country, flag: '🌍', lat: city.lat, lng: city.lng);
  }

  void onPopularCitySelected(PopularCity city) {
    analytics.logEvent(AnalyticsEvents.passportPopularCityTap, params: {
      AnalyticsEvents.paramDestinationCity: city.name,
    });
    navigateToConfirm(city: city.name, country: city.country, flag: city.flag, lat: city.lat, lng: city.lng);
  }

  Future<void> onDeactivate(Future<void> Function(Future<void> Function()) withLoading) async {
    final city = ref.read(passportProvider).city ?? '';
    await withLoading(() async {
      final result = await ref.read(passportProvider.notifier).deactivate();
      result.when(
        success: (_) {
          analytics.logEvent(AnalyticsEvents.passportDeactivate, params: {
            AnalyticsEvents.paramDestinationCity: city,
          });
        },
        failure: (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('passport_deactivate_failed'))),
            );
          }
        },
      );
    });
  }

  void onChangeCity(String? currentCity) {
    analytics.logEvent(AnalyticsEvents.passportChangeCity, params: {
      AnalyticsEvents.paramFromCity: currentCity ?? '',
    });
    setState(() => isChangingCity = true);
  }
}
