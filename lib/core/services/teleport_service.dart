import 'dart:developer' as dev;
import 'package:dio/dio.dart';

class TeleportCity {
  final String name;
  final String fullName;
  final double lat;
  final double lng;

  const TeleportCity({
    required this.name,
    required this.fullName,
    required this.lat,
    required this.lng,
  });
}

/// City search service using Nominatim (OpenStreetMap).
/// Free, no API key, worldwide coverage including districts.
/// Rate limit: 1 req/sec (our 300ms debounce is sufficient).
class TeleportService {
  TeleportService._();
  static final TeleportService instance = TeleportService._();

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {'User-Agent': 'QuloDatingApp/1.0'},
  ));

  /// Search cities/places by query. Throws on network error.
  Future<List<TeleportCity>> searchCities(String query) async {
    if (query.trim().length < 2) return [];

    final response = await _dio.get('/search', queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '10',
      'addressdetails': '1',
      'accept-language': 'en',
    });

    final results = (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];

    return results.map((item) {
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lng = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;

      final name = _extractName(item);
      final fullName = item['display_name'] as String? ?? name;

      return TeleportCity(name: name, fullName: fullName, lat: lat, lng: lng);
    }).whereType<TeleportCity>().toList();
  }

  /// Reverse geocode: get city/place name from coordinates.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get('/reverse', queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'en',
      });

      final address = response.data['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      return address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['municipality'] as String? ??
          address['county'] as String? ??
          address['state'] as String?;
    } catch (e) {
      dev.log('Reverse geocode failed: $e', name: 'TeleportService');
      return null;
    }
  }

  String _extractName(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>?;
    if (address != null) {
      return address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['municipality'] as String? ??
          item['name'] as String? ??
          (item['display_name'] as String? ?? '').split(',').first;
    }
    return item['name'] as String? ??
        (item['display_name'] as String? ?? '').split(',').first;
  }
}
