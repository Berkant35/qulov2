import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String? city;

  /// ISO 3166-1 alpha-2 (`TR`, `US`) — FormatManager ve sunucu `users.country` bu biçimi bekler.
  final String? countryCode;

  const LocationResult({required this.lat, required this.lng, this.city, this.countryCode});
}

/// Ters geocode sonucu — şehir ve ülke kodu aynı Placemark'tan gelir.
typedef PlaceInfo = ({String? city, String? countryCode});

class MockLocationException implements Exception {
  const MockLocationException();
  @override
  String toString() => 'LOCATION_MOCK_DETECTED';
}

class LocationManager {
  LocationManager._();
  static final LocationManager instance = LocationManager._();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  Future<LocationResult> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    // Mock location check — only in release mode (kDebugMode bypasses for emulator testing)
    if (!kDebugMode && position.isMocked) {
      throw const MockLocationException();
    }

    final place = await getPlaceFromCoordinates(position.latitude, position.longitude);
    return LocationResult(
      lat: position.latitude,
      lng: position.longitude,
      city: place.city,
      countryCode: place.countryCode,
    );
  }

  /// Ülke kodu eskiden burada düşürülüyordu; `users.country` tüm uygulama
  /// kullanıcılarında NULL kalmıştı (çok bölgeli kampanya ölçümü imkânsız).
  Future<PlaceInfo> getPlaceFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) return placeInfoFrom(placemarks.first);
    } catch (e, stack) {
      AnalyticsManager.instance.logNonFatalError(e, stack, context: 'geocoding_failed');
    }
    return (city: null, countryCode: null);
  }

  /// Placemark → şehir + ISO-2 ülke kodu. Kod normalize edilir (kırpma, büyük
  /// harf); iki harf değilse null — sunucu şeması `^[A-Z]{2}$` bekler.
  @visibleForTesting
  static PlaceInfo placeInfoFrom(Placemark p) {
    final code = p.isoCountryCode?.trim().toUpperCase();
    return (
      city: p.locality ?? p.administrativeArea,
      countryCode: (code != null && code.length == 2) ? code : null,
    );
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.always => LocationPermissionStatus.granted,
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}
