import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/rewards_service.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/data/repositories/rewards_repository.dart';

import '../../helpers/scripted_http_adapter.dart';

(RewardsRepository, ScriptedHttpAdapter) _repo(Future<ResponseBody> Function(RequestOptions) respond) {
  final adapter = ScriptedHttpAdapter(respond);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;
  return (RewardsRepository(RewardsService(dio)), adapter);
}

void main() {
  test('getMarket: ülke sorgu parametresi; yoksa parametre gitmez', () async {
    final (repo, adapter) = _repo((_) async => jsonResponse(200, {'balance': 7, 'items': [], 'sections': []}));
    final result = await repo.getMarket(country: 'TH');
    expect((result as Success<MarketView>).data.balance, 7);
    expect(adapter.requests.single.uri.queryParameters, {'country': 'TH'});
    await repo.getMarket();
    expect(adapter.requests.last.uri.queryParameters, isEmpty);
  });

  test('redeem: gövde + aynı Idempotency-Key başlığı + kaynak kart', () async {
    final (repo, adapter) = _repo((_) async => jsonResponse(200, {
          'redemption': {'id': 'r1', 'status': 'PENDING'},
          'balance': 949,
        }));
    final result = await repo.redeem(itemId: 'i1', idempotencyKey: 'k-1', sourceItemId: 'b1');
    expect((result as Success<RedeemResult>).data.balance, 949);
    final sent = adapter.requests.single;
    expect(sent.headers['Idempotency-Key'], 'k-1');
    expect(sent.data, {'item_id': 'i1', 'idempotency_key': 'k-1', 'source_item_id': 'b1'});
  });

  test('redeem: kaynak kart yoksa alan gönderilmez', () async {
    final (repo, adapter) = _repo((_) async => jsonResponse(200, {'redemption': {'id': 'r1'}, 'balance': 1}));
    await repo.redeem(itemId: 'i1', idempotencyKey: 'k-2');
    expect((adapter.requests.single.data as Map).containsKey('source_item_id'), isFalse);
  });

  test('403 REWARD_MONTHLY_CAP → ServerFailure + params {cap, used}', () async {
    final (repo, _) = _repo((_) async => jsonResponse(403, {
          'error': {'code': 'REWARD_MONTHLY_CAP', 'params': {'cap': 230, 'used': 220}},
        }));
    final result = await repo.redeem(itemId: 'i1', idempotencyKey: 'k-3');
    final failure = (result as Failure<RedeemResult>).failure as ServerFailure;
    expect(failure.code, 'REWARD_MONTHLY_CAP');
    expect(failure.params, {'cap': 230, 'used': 220});
  });

  test('bozuk yanıt çökmez → UnknownFailure', () async {
    final (repo, _) = _repo((_) async => jsonResponse(200, {'balance': 1}));
    final result = await repo.redeem(itemId: 'i1', idempotencyKey: 'k-4');
    expect((result as Failure<RedeemResult>).failure, isA<UnknownFailure>());
  });

  test('sendEvents: toplu gövde', () async {
    final (repo, adapter) = _repo((_) async => ResponseBody.fromString('', 204));
    final result = await repo.sendEvents(const [
      SectionEvent('b1', SectionEventType.impression),
      SectionEvent('b1', SectionEventType.click),
    ]);
    expect(result.isSuccess, isTrue);
    expect(jsonDecode(jsonEncode(adapter.requests.single.data)), {
      'events': [
        {'item_id': 'b1', 'event': 'impression'},
        {'item_id': 'b1', 'event': 'click'},
      ],
    });
  });

  test('getRedemptions: sayfa + limit parametreleri', () async {
    final (repo, adapter) = _repo((_) async => jsonResponse(200, {'items': [], 'total': 0, 'page': 3, 'limit': 20}));
    await repo.getRedemptions(page: 3);
    expect(adapter.requests.single.uri.queryParameters, {'page': '3', 'limit': '20'});
  });
}
