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

class TeleportService {
  TeleportService._();
  static final TeleportService instance = TeleportService._();

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.teleport.org/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Search cities by query. Throws on network/API error. Returns empty list for no results.
  Future<List<TeleportCity>> searchCities(String query) async {
    if (query.trim().length < 2) return [];

    final searchResponse = await _dio.get(
      '/cities/',
      queryParameters: {'search': query, 'limit': 10},
    );

    final embedded = searchResponse.data['_embedded'] as Map<String, dynamic>?;
    final results = (embedded?['city:search-results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Collect detail URLs, limit to first 5 for speed
    final detailFutures = <Future<TeleportCity?>>[];
    for (final result in results.take(5)) {
      final fullName = result['matching_full_name'] as String? ?? '';
      final links = result['_links'] as Map<String, dynamic>?;
      final cityItemHref = (links?['city:item'] as Map<String, dynamic>?)?['href'] as String?;

      if (cityItemHref == null) continue;

      detailFutures.add(_fetchCityDetail(cityItemHref, fullName));
    }

    // Fetch details in parallel
    final detailResults = await Future.wait(detailFutures);
    return detailResults.whereType<TeleportCity>().toList();
  }

  Future<TeleportCity?> _fetchCityDetail(String href, String fullName) async {
    try {
      final detailResponse = await _dio.get(href);
      final location = detailResponse.data['location'] as Map<String, dynamic>?;
      final latlon = location?['latlon'] as Map<String, dynamic>?;

      if (latlon == null) return null;

      final lat = (latlon['latitude'] as num?)?.toDouble();
      final lng = (latlon['longitude'] as num?)?.toDouble();
      final name = detailResponse.data['name'] as String? ?? fullName.split(',').first;

      if (lat != null && lng != null) {
        return TeleportCity(name: name, fullName: fullName, lat: lat, lng: lng);
      }
    } catch (e) {
      dev.log('Teleport detail fetch failed for $href: $e', name: 'TeleportService');
    }
    return null;
  }
}
