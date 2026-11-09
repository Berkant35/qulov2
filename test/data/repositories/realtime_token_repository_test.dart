import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/realtime_token_service.dart';
import 'package:qulo_v2/data/models/realtime_token_model.dart';
import 'package:qulo_v2/data/repositories/realtime_token_repository.dart';

import '../../helpers/scripted_http_adapter.dart';

/// Realtime kullanıcı token'ı (2.0.18 P0): sözleşme `tasks/surum-2.0.18-sozlesmeler.md`.
/// Gerçek servis + senaryolu sunucu: yol, yöntem ve hata kodu eşlemesi birlikte sınanır.
void main() {
  late ScriptedHttpAdapter server;

  RealtimeTokenRepository repo(Future<ResponseBody> Function(RequestOptions o) respond) {
    server = ScriptedHttpAdapter(respond);
    return RealtimeTokenRepository(RealtimeTokenService(scriptedDio(server)));
  }

  test('200 → token ve bitiş (UTC); istek POST /realtime/token, gövdesiz', () async {
    final r = repo((_) async => jsonResponse(200, {
          'token': 'jwt-1',
          'expiresAt': '2026-11-09T13:00:00.000Z',
        }));

    final result = await r.issue();

    final token = (result as Success<RealtimeToken>).data;
    expect(token.token, 'jwt-1');
    expect(token.expiresAt, DateTime.utc(2026, 11, 9, 13));
    expect(server.requests.single.method, 'POST');
    expect(server.requests.single.path, '/realtime/token');
    expect(server.requests.single.data, isNull);
  });

  test('503 REALTIME_TOKEN_UNAVAILABLE → ServerFailure kodu korunur (çağıran anon sürer)', () async {
    final r = repo((_) async => jsonResponse(503, {
          'error': {'code': RealtimeTokenService.unavailableCode, 'message': 'no signer'},
        }));

    final failure = ((await r.issue()) as Failure<RealtimeToken>).failure;

    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).code, 'REALTIME_TOKEN_UNAVAILABLE');
    expect(failure.statusCode, 503);
  });

  test('429 RATE_LIMITED → ServerFailure', () async {
    final r = repo((_) async => jsonResponse(429, {
          'error': {'code': 'RATE_LIMITED'},
        }));

    final failure = ((await r.issue()) as Failure<RealtimeToken>).failure;

    expect((failure as ServerFailure).code, 'RATE_LIMITED');
  });

  test('ağ hatası → NetworkFailure', () async {
    final r = repo((o) async => throw DioException(requestOptions: o, type: DioExceptionType.connectionError));

    expect(((await r.issue()) as Failure<RealtimeToken>).failure, isA<NetworkFailure>());
  });

  test('eksik alanlı 200 (bozuk yanıt) → çökmez, Failure', () async {
    final r = repo((_) async => jsonResponse(200, {'token': 'jwt-1'}));

    final failure = ((await r.issue()) as Failure<RealtimeToken>).failure;

    expect((failure as ServerFailure).code, RealtimeTokenRepository.malformedCode);
  });
}
