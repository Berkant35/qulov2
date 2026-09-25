import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Kayit ve profil tamamlama adimlarinin ortak konum istegi.
///
/// Izin diyalogu + GPS saniyeler surer; kullanici bu arada "Atla/Devam" ile
/// ekrandan cikabilir. Sonuc tek noktada, yalnizca ekran hala acikken
/// state'e yazilir (Crashlytics: dispose sonrasi `setState` null-check).
mixin LocationRequestMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  double? lat;
  double? lng;
  bool locationGranted = false;
  bool isRequestingLocation = false;
  String? locationError;

  Future<void> requestLocation() async {
    setState(() {
      isRequestingLocation = true;
      locationError = null;
    });

    final manager = ref.read(locationManagerProvider);
    LocationResult? position;
    String? errorKey;
    try {
      errorKey = await _permissionErrorKey(manager);
      if (errorKey == null) position = await manager.getCurrentPosition();
    } catch (_) {
      // Ham istisna metni (Ingilizce, platforma ozgu) kullaniciya gosterilmez.
      errorKey = 'error_general';
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      isRequestingLocation = false;
      locationError = errorKey == null ? null : l10n.get(errorKey);
      if (position != null) {
        lat = position.lat;
        lng = position.lng;
        locationGranted = true;
      }
    });
  }

  static Future<String?> _permissionErrorKey(LocationManager manager) async {
    if (!await manager.isServiceEnabled()) return 'location_service_disabled';
    var permission = await manager.checkPermission();
    if (permission == LocationPermissionStatus.denied) {
      permission = await manager.requestPermission();
    }
    return switch (permission) {
      LocationPermissionStatus.granted => null,
      LocationPermissionStatus.denied => 'location_permission_denied',
      LocationPermissionStatus.deniedForever => 'location_permission_denied_forever',
    };
  }
}
