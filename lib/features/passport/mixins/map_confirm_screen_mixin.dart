import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/passport/screens/map_confirm_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';

mixin MapConfirmScreenMixin on ConsumerState<MapConfirmScreen>, LoadingMixin<MapConfirmScreen> {
  final Completer<GoogleMapController> mapController = Completer();
  bool isMapReady = false;
  String? mapStyle;

  late LatLng currentPosition;
  late String currentCity;
  bool isLoadingCity = false;

  void initMixin() {
    currentPosition = LatLng(widget.lat, widget.lng);
    currentCity = widget.cityName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.passportMapConfirmView,
        params: {AnalyticsEvents.paramDestinationCity: widget.cityName},
      );
    });
  }

  void disposeMixin() {
    // Reserved for future cleanup
  }

  /// Acilis kamerasi: secilen sehir, genis aci; harita hazir olunca
  /// [onMapCreated] [_focusZoom]'a yaklastirir.
  static const double _initialZoom = 12;
  static const double _focusZoom = 14;

  LatLng get _cityTarget => LatLng(widget.lat, widget.lng);

  CameraPosition get initialCameraPosition =>
      CameraPosition(target: _cityTarget, zoom: _initialZoom);

  /// Haritayi gorunur yapar, kisa bir beklemeden sonra sehre yaklasir.
  Future<void> onMapCreated(GoogleMapController controller) async {
    if (!mapController.isCompleted) mapController.complete(controller);
    if (!mounted) return;
    setState(() => isMapReady = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _cityTarget, zoom: _focusZoom),
      ),
    );
  }

  Future<void> loadMapStyle() async {
    final brightness = Theme.of(context).brightness;
    final path = brightness == Brightness.dark
        ? AppAssets.mapStyleDark
        : AppAssets.mapStyleLight;
    try {
      final style = await rootBundle.loadString(path);
      if (mounted) setState(() => mapStyle = style);
    } catch (_) {}
  }

  void onCameraMove(CameraPosition position) {
    currentPosition = position.target;
  }

  Future<void> onCameraIdle() async {
    if (!mounted) return;
    setState(() => isLoadingCity = true);
    try {
      final service = ref.read(teleportServiceProvider);
      final city = await service.reverseGeocode(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      if (mounted) {
        setState(() {
          if (city != null && city.isNotEmpty) currentCity = city;
          isLoadingCity = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingCity = false);
    }
  }

  Future<void> onConfirm() async {
    final nav = ref.read(navigationServiceProvider);
    final cityToActivate = currentCity;
    final latToActivate = currentPosition.latitude;
    final lngToActivate = currentPosition.longitude;

    await withLoading(() async {
      final passport = ref.read(passportProvider);
      final Result result;
      if (passport.isActive) {
        result = await ref.read(passportProvider.notifier).changeCity(
          city: cityToActivate, lat: latToActivate, lng: lngToActivate,
        );
      } else {
        result = await ref.read(passportProvider.notifier).activate(
          city: cityToActivate, lat: latToActivate, lng: lngToActivate,
        );
      }
      
      result.when(
        success: (_) {
          AnalyticsManager.instance.logEvent(
            AnalyticsEvents.passportExploreStart,
            params: {AnalyticsEvents.paramDestinationCity: cityToActivate},
          );
          // Istek surerken "Geri" ile cikildiysa bu ekran zaten kapandi: pop
          // ALTTAKI pasaport ekranini kapatirdi.
          if (mounted) nav.pop();
        },
        failure: (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('passport_activate_failed'))),
            );
          }
        },
      );
    });
  }
}
