import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/diamond_service.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/repositories/diamond_repository.dart';

/// Elmas repository'si — para yolu, o yüzden ilk yazılan repository testi.
///
/// Servis fake'i elle yazıldı (mocktail'e gerek kalmadı): Retrofit servisi
/// abstract, implement etmek yeterli. Fake gönderilen payload'ı saklıyor,
/// böylece "ne gönderildi" doğrulanabiliyor — asıl mesele o.
class _FakeDiamondService implements DiamondService {
  _FakeDiamondService({this.balance, this.history, this.error});

  final DiamondBalance? balance;
  final DiamondHistoryResponse? history;
  final DioException? error;

  Map<String, dynamic>? lastPurchasePayload;
  int? lastPage;
  int? lastLimit;
  int purchaseCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<DiamondBalance> getBalance() async {
    if (error != null) throw _err;
    return balance!;
  }

  @override
  Future<DiamondHistoryResponse> getHistory(int page, int limit) async {
    lastPage = page;
    lastLimit = limit;
    if (error != null) throw _err;
    return history!;
  }

  @override
  Future<void> purchase(Map<String, dynamic> data) async {
    purchaseCallCount++;
    lastPurchasePayload = data;
    if (error != null) throw _err;
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
  group('getBalance', () {
    test('başarılı yanıt Success olarak sarılır', () async {
      const balance = DiamondBalance(green: 12, purple: 30);
      final repo = DiamondRepository(_FakeDiamondService(balance: balance));

      final result = await repo.getBalance();

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d.purple, failure: (_) => -1), 30);
    });

    test('ağ hatası Failure(NetworkFailure) olur — bakiye ekranı boş göstermemeli', () async {
      final repo = DiamondRepository(
        _FakeDiamondService(error: _dio(DioExceptionType.connectionError)),
      );

      final result = await repo.getBalance();

      expect(result.isFailure, isTrue);
      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });

    test('sunucu hata kodu ServerFailure olarak taşınır', () async {
      final repo = DiamondRepository(_FakeDiamondService(
        error: _dio(DioExceptionType.badResponse,
            status: 402, body: {'error': {'code': 'INSUFFICIENT_DIAMONDS'}}),
      ));

      final result = await repo.getBalance();

      final failure = result.when(success: (_) => null, failure: (f) => f);
      expect((failure as ServerFailure).code, 'INSUFFICIENT_DIAMONDS');
      expect(failure.statusCode, 402);
    });
  });

  group('getHistory', () {
    test('varsayılan sayfalama servise 1/20 olarak gider', () async {
      final fake = _FakeDiamondService(
        history: const DiamondHistoryResponse(items: [], total: 0, page: 1, limit: 20),
      );

      await DiamondRepository(fake).getHistory();

      expect(fake.lastPage, 1);
      expect(fake.lastLimit, 20);
    });

    test('verilen sayfalama olduğu gibi geçer', () async {
      final fake = _FakeDiamondService(
        history: const DiamondHistoryResponse(items: [], total: 0, page: 1, limit: 20),
      );

      await DiamondRepository(fake).getHistory(page: 3, limit: 50);

      expect(fake.lastPage, 3);
      expect(fake.lastLimit, 50);
    });
  });

  group('purchase — para yolu', () {
    test('platform sabit değil, cihazdan geliyor', () async {
      // Onceden 'ios' sabit yaziliydi; Android satin alimlari da iOS
      // gorunuyordu. Sunucu bugun alani okumuyor ama sozlesme
      // (diamond.validator.ts: z.enum(["android","ios"])) ikisini de kabul
      // ediyor ve dogru olani gonderilmeli.
      final fake = _FakeDiamondService();

      await DiamondRepository(fake).purchase('qulopurple400');

      expect(fake.lastPurchasePayload!['platform'], Platform.isIOS ? 'ios' : 'android');
      expect(['ios', 'android'], contains(fake.lastPurchasePayload!['platform']));
    });

    test('product_id gönderilir', () async {
      final fake = _FakeDiamondService();

      await DiamondRepository(fake).purchase('qulopurple2500');

      expect(fake.lastPurchasePayload!['product_id'], 'qulopurple2500');
    });

    test('transaction_id verilince payload\'a eklenir', () async {
      final fake = _FakeDiamondService();

      await DiamondRepository(fake).purchase('qulopurple50', transactionId: 'tx-123');

      expect(fake.lastPurchasePayload!['transaction_id'], 'tx-123');
    });

    test('transaction_id yoksa anahtar HİÇ gönderilmez, null olarak değil', () async {
      // Sunucu tarafinda null bir transaction_id, dogrulamada "gecersiz makbuz"
      // ile karistirilabilir; anahtarin hic olmamasi ile null olmasi ayni sey degil.
      final fake = _FakeDiamondService();

      await DiamondRepository(fake).purchase('qulopurple50');

      expect(fake.lastPurchasePayload!.containsKey('transaction_id'), isFalse);
    });

    test('başarılı satın alma Success(null) döner', () async {
      final result = await DiamondRepository(_FakeDiamondService()).purchase('qulopurple150');

      expect(result.isSuccess, isTrue);
    });

    test('hata durumunda Failure döner ve servis bir kez çağrılır — sessiz tekrar yok', () async {
      // Para yolunda gizli bir retry, cift kredilendirme riski demek.
      final fake = _FakeDiamondService(error: _dio(DioExceptionType.receiveTimeout));

      final result = await DiamondRepository(fake).purchase('qulopurple1000');

      expect(result.isFailure, isTrue);
      expect(result.when(success: (_) => null, failure: (f) => f), isA<TimeoutFailure>());
      expect(fake.purchaseCallCount, 1);
    });
  });
}
