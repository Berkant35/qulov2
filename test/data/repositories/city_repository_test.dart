import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/city_service.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/repositories/city_repository.dart';

import '../../helpers/scripted_http_adapter.dart';

/// Konumsuz yedek yol (2.0.18 madde 9). Sözleşme: `tasks/surum-2.0.18-sozlesmeler.md` §3.
void main() {
  late ScriptedHttpAdapter server;

  CityRepository repo(Future<ResponseBody> Function(RequestOptions o) respond) {
    server = ScriptedHttpAdapter(respond);
    return CityRepository(CityService(scriptedDio(server)));
  }

  group('arama — GET /app/cities', () {
    test('ülke, arama ve limit sorguya gider; ülkeler ve şehirler okunur', () async {
      final r = repo((_) async => jsonResponse(200, {
            'countries': ['TR', 'IT'],
            'cities': [
              {'id': 'TR-istanbul', 'name': 'İstanbul', 'country': 'TR'},
            ],
          }));

      final data = ((await r.search(country: 'TR', query: ' ist ')) as Success<CityListResponse>).data;

      final req = server.requests.single;
      expect(req.method, 'GET');
      expect(req.path, '/app/cities');
      expect(req.queryParameters, {'country': 'TR', 'q': 'ist', 'limit': 100});
      expect(data.countries, ['TR', 'IT']);
      expect(data.cities.single.name, 'İstanbul');
    });

    test('boş arama ve ülkesiz istek parametre taşımaz (sunucu ilk 100 şehri döner)', () async {
      final r = repo((_) async => jsonResponse(200, {'countries': [], 'cities': []}));

      await r.search();

      expect(server.requests.single.queryParameters, {'limit': 100});
    });

    test('50 karakterden uzun arama kırpılır (sunucu sınırı, 400 olmasın)', () async {
      final r = repo((_) async => jsonResponse(200, {'countries': [], 'cities': []}));

      await r.search(query: 'a' * 80);

      expect((server.requests.single.queryParameters['q'] as String).length, 50);
    });

    test('bozuk satır atlanır, eksik alan çökmez', () async {
      final r = repo((_) async => jsonResponse(200, {
            'cities': [
              {'id': 'TR-izmir', 'name': 'İzmir', 'country': 'TR'},
              {'id': 'TR-x'},
            ],
          }));

      final data = ((await r.search()) as Success<CityListResponse>).data;

      expect(data.cities.map((c) => c.id), ['TR-izmir']);
      expect(data.countries, isEmpty);
    });

    test('ağ hatası → NetworkFailure', () async {
      final r = repo((o) async => throw DioException(requestOptions: o, type: DioExceptionType.connectionError));

      expect(((await r.search()) as Failure).failure, isA<NetworkFailure>());
    });
  });

  group('kaydetme — PATCH /users/me/location/city', () {
    test('gövde {city_id}', () async {
      final r = repo((_) async => jsonResponse(200, {
            'city_id': 'TR-istanbul',
            'city': 'İstanbul',
            'country': 'TR',
            'location_source': 'city',
          }));

      final result = await r.setCity('TR-istanbul');

      expect(result, isA<Success<void>>());
      expect(server.requests.single.method, 'PATCH');
      expect(server.requests.single.path, '/users/me/location/city');
      expect(server.requests.single.data, {'city_id': 'TR-istanbul'});
    });

    test('404 CITY_NOT_FOUND kodu korunur', () async {
      final r = repo((_) async => jsonResponse(404, {
            'error': {'code': 'CITY_NOT_FOUND'},
          }));

      final failure = ((await r.setCity('TR-yok')) as Failure).failure;

      expect((failure as ServerFailure).code, CityRepository.cityNotFoundCode);
    });
  });
}
