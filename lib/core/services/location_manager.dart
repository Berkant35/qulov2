import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String? city;

  const LocationResult({required this.lat, required this.lng, this.city});
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
    final city = await getCityFromCoordinates(position.latitude, position.longitude);
    return LocationResult(lat: position.latitude, lng: position.longitude, city: city);
  }

  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? placemarks.first.administrativeArea;
      }
    } catch (_) {}
    return null;
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
