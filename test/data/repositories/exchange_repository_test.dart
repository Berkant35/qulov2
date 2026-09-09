import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/exchange_service.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/repositories/exchange_repository.dart';

/// Takas repository'si — yeşil→mor dönüşümü ve güç satın alma.
///
/// Sunucu sözleşmesi (`exchange.validator.ts`):
///   green_amount  → int, 1..1_000_000 (oran kontrolü **serviste**, config'ten)
///   power_name    → 8 değerli enum (POWER_BLOCK/POWER_UNBLOCK dahil)
///   diamond_type  → GREEN | PURPLE
///   quantity      → int, 1..50
///
/// Dönüşüm oranı SABİT DEĞİL: `greenToPurpleRatio` backoffice'ten 1-10 arasına
/// çekilebiliyor, mobil onu `rates` yanıtından okuyor. Bu yüzden repository
/// katmanı miktar üzerinde hiçbir varsayım yapmamalı — testler bunu koruyor.
class _FakeExchangeService implements ExchangeService {
  _FakeExchangeService({this.convertRatio = 3, this.error});

  final int convertRatio;
  final DioException? error;

  Map<String, dynamic>? lastConvertPayload;
  Map<String, dynamic>? lastBuyPowerPayload;
  int convertCallCount = 0;
  int buyPowerCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<ConvertResponse> convert(Map<String, dynamic> data) async {
    convertCallCount++;
    lastConvertPayload = data;
    if (error != null) throw _err;
    final green = data['green_amount'] as int;
    return ConvertResponse(
      purpleReceived: green ~/ convertRatio,
      newBalance: const DiamondBalance(green: 0, purple: 0),
    );
  }

  @override
  Future<BuyPowerResponse> buyPower(Map<String, dynamic> data) async {
    buyPowerCallCount++;
    lastBuyPowerPayload = data;
    if (error != null) throw _err;
    return const BuyPowerResponse(
      newCount: 2,
      newBalance: DiamondBalance(green: 10, purple: 5),
    );
  }

  @override
  Future<InventoryResponse> getInventory() async {
    if (error != null) throw _err;
    return const InventoryResponse(
      inventory: [PowerInventoryItem(powerName: 'SKIP', count: 2)],
    );
  }

  @override
  Future<RatesResponse> getRates() async {
    if (error != null) throw _err;
    return RatesResponse(convertRatio: convertRatio, powers: const []);
  }
}

DioException _dio(DioExceptionType type, {int? status, dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
              data: body,
            ),
    );

void main() {
  group('convert — dönüşüm oranı varsayımı yok', () {
    test('miktar payload olarak olduğu gibi gider', () async {
      final fake = _FakeExchangeService();

      await ExchangeRepository(fake).convert(9);

      expect(fake.lastConvertPayload, {'green_amount': 9});
    });

    test('3ün katı olmayan miktar da gönderilir — repository engellemez', () async {
      // Oran 4 iken 8 geçerli bir istektir. Repository'nin miktar üzerinde
      // varsayım yapması, oran değiştiğinde sessizce kırılırdı.
      final fake = _FakeExchangeService(convertRatio: 4);

      final result = await ExchangeRepository(fake).convert(8);

      expect(fake.lastConvertPayload, {'green_amount': 8});
      expect(result.when(success: (d) => d.purpleReceived, failure: (_) => -1), 2);
    });

    test('sunucu doğrulama hatası ServerFailure olarak taşınır', () async {
      // Oranın katı olmayan miktarı sunucu reddediyor (exchange.service.ts:11).
      final fake = _FakeExchangeService(
        error: _dio(DioExceptionType.badResponse,
            status: 400, body: {'error': {'code': 'VALIDATION_ERROR'}}),
      );

      final result = await ExchangeRepository(fake).convert(5);

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'VALIDATION_ERROR');
    });

    test('hata durumunda servis TAM BİR KEZ çağrılır — sessiz tekrar yok', () async {
      // Dönüşüm çok adımlı ve transaction'sız (bkz. qulo-server CLAUDE.md
      // "atomiklik sınırı"): gizli bir retry elmasın iki kez düşmesi demek.
      final fake = _FakeExchangeService(error: _dio(DioExceptionType.receiveTimeout));

      await ExchangeRepository(fake).convert(9);

      expect(fake.convertCallCount, 1);
    });
  });

  group('buyPower', () {
    test('üç alan da payload olarak gider', () async {
      final fake = _FakeExchangeService();

      await ExchangeRepository(fake).buyPower('SKIP', 'GREEN', 3);

      expect(fake.lastBuyPowerPayload,
          {'power_name': 'SKIP', 'diamond_type': 'GREEN', 'quantity': 3});
    });

    test('POWER_BLOCK sunucu enumundaki adla gönderilir', () async {
      // Bu alan üç kez yanlış adla gönderilip geri alınmıştı; ad sözleşmesi
      // burada donduruluyor.
      final fake = _FakeExchangeService();

      await ExchangeRepository(fake).buyPower('POWER_BLOCK', 'PURPLE', 1);

      expect(fake.lastBuyPowerPayload!['power_name'], 'POWER_BLOCK');
      expect(fake.lastBuyPowerPayload!['diamond_type'], 'PURPLE');
    });

    test('yetersiz bakiye ServerFailure olarak taşınır — paywall buna bakıyor', () async {
      final fake = _FakeExchangeService(
        error: _dio(DioExceptionType.badResponse,
            status: 402, body: {'error': {'code': 'INSUFFICIENT_DIAMONDS'}}),
      );

      final result = await ExchangeRepository(fake).buyPower('SKIP', 'PURPLE', 1);

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INSUFFICIENT_DIAMONDS');
      expect(fake.buyPowerCallCount, 1);
    });
  });

  group('getInventory / getRates', () {
    test('envanter listesi modele geçer', () async {
      final result = await ExchangeRepository(_FakeExchangeService()).getInventory();

      final data = result.when(success: (d) => d, failure: (_) => null)!;
      expect(data.inventory.single.powerName, 'SKIP');
      expect(data.inventory.single.count, 2);
    });

    test('oran sunucudan okunur — istemcide sabit değil', () async {
      // Mobil dönüşüm ekranı bu değeri kullanıyor; sabitlenirse backoffice'ten
      // yapılan oran değişikliği istemcide görünmez ve istekler reddedilir.
      final result = await ExchangeRepository(_FakeExchangeService(convertRatio: 7)).getRates();

      expect(result.when(success: (d) => d.convertRatio, failure: (_) => -1), 7);
    });

    test('ağ hatası Failure olur', () async {
      final fake = _FakeExchangeService(error: _dio(DioExceptionType.connectionError));

      final result = await ExchangeRepository(fake).getRates();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });
}
